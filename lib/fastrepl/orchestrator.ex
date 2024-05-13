defmodule Fastrepl.Orchestrator do
  use GenServer
  require Logger

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Repository
  alias Fastrepl.Retrieval
  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Vectordb
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
      |> Map.put(:current_step, "Initialization")
      |> Map.put(:messages, [])
      |> Map.put(:vector_db, %{pid: nil, indexing_progress: nil, indexing_total: nil})

    send(
      state.orchestrator_pid,
      {:fetch_issue, %{repo_full_name: args.repo_full_name, issue_number: args.issue_number}}
    )

    send(state.orchestrator_pid, :clone_repo)

    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply,
     %{
       repo: state.repo,
       github_issue: state.github_issue,
       current_step: state.current_step,
       messages: state.messages,
       vector_db: state.vector_db
     }, state}
  end

  @impl true
  def handle_call(:patch, _from, state) do
    patch = state.repo.diffs |> Enum.map(&Repository.Diff.to_patch/1) |> Enum.join("\n")
    {:reply, patch, state}
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
    |> Enum.group_by(& &1.file_path)
    |> Enum.each(fn {_file_path, comments} ->
      Task.start(fn ->
        diffs =
          comments
          |> Enum.map(&Fastrepl.SemanticFunction.Modify.run!(state.repo, &1))
          |> Enum.reduce(state.repo, &Repository.Mutation.run!(&2, &1))
          |> Repository.Diff.from()

        send(state.orchestrator_pid, {:diffs, diffs})
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
  def handle_info({:fetch_issue, data}, state) do
    new_data = %{
      github_issue: Github.get_issue!(data.repo_full_name, data.issue_number),
      github_issue_comments: Github.list_issue_comments!(data.repo_full_name, data.issue_number)
    }

    sync_with_views(state.thread_id, new_data)
    {:noreply, state |> Map.merge(new_data)}
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
    if state.vector_db.pid do
      Vectordb.stop(state.vector_db.pid)
    end

    {:ok, pid} = Vectordb.start(state.thread_id)

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
        pid,
        chunks,
        fn n -> send(state.orchestrator_pid, {:repo_indexing, {:progress, n}}) end
      )

      send(state.orchestrator_pid, {:repo_indexing, {:done, length(chunks)}})
    end)

    state =
      state
      |> Map.put(:repo, %{state.repo | root_path: root_path, paths: paths})
      |> Map.put(:vector_db, %{state.vector_db | pid: pid})

    sync_with_views(state.thread_id, %{repo: state.repo, vector_db: state.vector_db})
    {:noreply, state}
  end

  @impl true
  def handle_info({:repo_indexing, {type, value}}, state) do
    state =
      case type do
        :start ->
          state
          |> Map.put(:vector_db, %{state.vector_db | indexing_progress: 0, indexing_total: value})

        :progress ->
          progress = (state.vector_db.indexing_progress || 0) + value

          state
          |> Map.put(:vector_db, %{state.vector_db | indexing_progress: progress})

        :done ->
          state |> Map.put(:vector_db, %{state.vector_db | indexing_progress: value})
      end

    sync_with_views(state.thread_id, %{vector_db: state.vector_db})
    {:noreply, state}
  end

  @impl true
  def handle_info({:chunks, chunks}, state) do
    chunks = Chunker.dedupe(state.repo.chunks ++ chunks)

    repo = state.repo |> Map.put(:chunks, chunks)
    sync_with_views(state.thread_id, %{repo: repo})
    {:noreply, state |> Map.put(:repo, repo)}
  end

  @impl true
  def handle_info({:diffs, diffs}, state) do
    new_diffs = state.repo.diffs ++ diffs
    state = state |> Map.put(:repo, %{state.repo | diffs: new_diffs})
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
