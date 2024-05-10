defmodule Fastrepl.Orchestrator do
  use GenServer
  require Logger

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Repository

  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Vectordb

  alias Fastrepl.Native.CodeUtils
  alias Fastrepl.SemanticFunction.PlanningChat

  def start(%{thread_id: thread_id, repo_full_name: _, issue_number: _} = args) do
    GenServer.start(__MODULE__, args, name: via_registry(thread_id, args[:is_demo]))
  end

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    state =
      %{}
      |> Map.put(:orchestrator_pid, self())
      |> Map.put(:thread_id, args.thread_id)
      |> Map.put(:repo, %Repository{full_name: args.repo_full_name})
      |> Map.put(:issue, %{title: "", number: args.issue_number, comments: []})
      |> Map.put(:current_step, "Initialization")
      |> Map.put(:messages, [])

    send(state.orchestrator_pid, :fetch_issue)
    send(state.orchestrator_pid, :clone_repo)

    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply,
     %{
       repo: state.repo,
       issue: state.issue,
       current_step: state.current_step,
       messages: state.messages
     }, state}
  end

  @impl true
  def handle_call(:patch, _from, state) do
    {:reply, state.repo.diffs |> Enum.join("\n"), state}
  end

  @impl true
  def handle_cast({:sync, map}, state) when is_map(map) do
    state = map |> Enum.reduce(state, fn {k, v}, acc -> Map.put(acc, k, v) end)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:chat, %{messages: messages, references: references}}, state) do
    callback = fn
      {:update, content} ->
        send(
          state.orchestrator_pid,
          {:response_update, %{content: content}}
        )

      {:complete, content} ->
        send(
          state.orchestrator_pid,
          {:response_complete, %{content: content}}
        )
    end

    PlanningChat.run(%{messages: messages, references: references}, callback)
    {:noreply, state |> Map.put(:messages, messages)}
  end

  @impl true
  def handle_cast(:execute, state) do
    state.repo.comments
    |> Enum.map(&Map.new(&1, fn {k, v} -> {String.to_existing_atom(k), v} end))
    |> Enum.map(&struct!(Fastrepl.Repository.Comment, &1))
    |> Enum.map(fn comment ->
      file = Repository.File.from!(state.repo.root_path, comment.file_path)
      {comment, file}
    end)
    |> Enum.each(fn {comment, file} ->
      Task.start(fn ->
        {:ok, modified_file} = Fastrepl.SemanticFunction.Modify.run(file, [comment])

        send(
          state.orchestrator_pid,
          {:diff,
           CodeUtils.unified_diff(
             file.path,
             modified_file.path,
             file.content,
             modified_file.content
           )}
        )
      end)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({action, %{content: content}}, state)
      when action in [:response_update, :response_complete] do
    messages =
      case action do
        :response_update ->
          state.messages
          |> List.update_at(
            -1,
            fn message -> %{message | content: message.content <> content} end
          )

        :response_complete ->
          state.messages
          |> List.replace_at(
            -1,
            %{role: "assistant", content: content}
          )
      end

    if should_broadcast?(state, action) do
      sync_with_views(state.thread_id, %{messages: messages})
    end

    {:noreply, state |> Map.put(:messages, messages)}
  end

  @impl true
  def handle_info(:fetch_issue, state) do
    issue = Github.get_issue!(state.repo.full_name, state.issue.number)
    comments = Github.list_issue_comments!(state.repo.full_name, state.issue.number)

    state = state |> Map.put(:issue, %{state.issue | title: issue.title, comments: comments})

    sync_with_views(state.thread_id, %{issue: state.issue})
    {:noreply, state}
  end

  @impl true
  def handle_info(:clone_repo, state) do
    repo = state.repo.full_name |> Github.get_repo!()
    repo_sha = repo |> Github.get_latest_commit!()

    Task.start(fn ->
      repo_url = Github.URL.clone_without_token(state.repo.full_name)

      {:ok, root_path} =
        FS.new_repo(
          Application.fetch_env!(:fastrepl, :clone_dir),
          repo_url,
          state.repo.full_name,
          repo_sha
        )

      send(state.orchestrator_pid, {:post_clone_repo, root_path})
    end)

    state = state |> Map.put(:repo, %{state.repo | sha: repo_sha, description: repo.description})
    sync_with_views(state.thread_id, %{repo: state.repo})
    {:noreply, state}
  end

  @impl true
  def handle_info({:post_clone_repo, root_path}, state) do
    if state.repo.vectordb_pid do
      Vectordb.stop(state.repo.vectordb_pid)
    end

    {:ok, vectordb_pid} = Vectordb.start(state.thread_id)

    paths =
      root_path
      |> FS.list_informative_files()
      |> Enum.map(&Path.relative_to(&1, root_path))

    chunks =
      root_path
      |> FS.list_informative_files()
      |> Enum.flat_map(&Chunker.chunk_file/1)

    Task.start(fn ->
      send(state.orchestrator_pid, {:repo_indexing, {:start, length(chunks)}})

      Vectordb.ingest(
        vectordb_pid,
        chunks,
        fn n -> send(state.orchestrator_pid, {:repo_indexing, {:progress, n}}) end
      )

      send(state.orchestrator_pid, {:repo_indexing, {:done, length(chunks)}})
    end)

    state =
      state
      |> Map.put(:repo, %{
        state.repo
        | root_path: root_path,
          paths: paths,
          vectordb_pid: vectordb_pid
      })

    sync_with_views(state.thread_id, %{repo: state.repo})
    {:noreply, state}
  end

  @impl true
  def handle_info({:repo_indexing, {type, value}}, state) do
    state =
      case type do
        :start ->
          state |> Map.put(:repo, %{state.repo | indexing_progress: 0, indexing_total: value})

        :progress ->
          progress = (state.repo.indexing_progress || 0) + value

          state
          |> Map.put(:repo, %{state.repo | indexing_progress: progress})

        :done ->
          state |> Map.put(:repo, %{state.repo | indexing_progress: value})
      end

    sync_with_views(state.thread_id, %{repo: state.repo})
    {:noreply, state}
  end

  @impl true
  def handle_info({:chunks, chunks}, state) do
    chunks = Chunker.dedupe(state.repo.chunks ++ chunks)

    repo =
      state.repo
      |> Map.put(:chunks, chunks)
      |> Map.put(:files, Enum.map(chunks, &Repository.File.from/1))

    sync_with_views(state.thread_id, %{repo: repo})
    {:noreply, state |> Map.put(:repo, repo)}
  end

  @impl true
  def handle_info({:diff, content}, state) do
    state = state |> Map.put(:repo, %{state.repo | diffs: [content | state.repo.diffs]})
    sync_with_views(state.thread_id, %{repo: state.repo})
    {:noreply, state}
  end

  @impl true
  def handle_info({:EXIT, _pid, reason}, state) do
    {:stop, reason, state}
  end

  @impl true
  def terminate(_reason, state) do
    if state[:thread_id] do
      Registry.unregister(registry_module(), state.thread_id)
    end

    state.repo |> Repository.clean_up()
    :ok
  end

  defp via_registry(id, is_demo) do
    {:via, Registry, {registry_module(), id, %{type: if(is_demo, do: :demo, else: :live)}}}
  end

  defp registry_module() do
    Application.fetch_env!(:fastrepl, :orchestrator_registry)
  end

  defp sync_with_views(thread_id, state) when is_map(state) do
    Phoenix.PubSub.broadcast(Fastrepl.PubSub, "thread:#{thread_id}", {:sync, state})
  end

  defp should_broadcast?(state, action) do
    if state[:last_broadcasted_at] == nil do
      true
    else
      diff = DateTime.utc_now() |> DateTime.diff(state.last_broadcasted_at, :millisecond)
      diff > 180 or action == :response_complete
    end
  end
end
