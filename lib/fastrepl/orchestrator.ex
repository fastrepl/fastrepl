defmodule Fastrepl.Orchestrator do
  use GenServer
  require Logger

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Repository
  alias Fastrepl.Retrieval
  alias Fastrepl.SemanticFunction.PlanningChat

  @precompute_batch_size 50

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
      |> Map.put(:indexing, %{progress: nil, total: nil})
      |> Map.put(:tasks, %{})

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
       indexing: state.indexing
     }, state}
  end

  @impl true
  def handle_call(:patch, _from, state) do
    patch = state.repo.diffs |> Enum.map(&Repository.Diff.to_patch/1) |> Enum.join("\n")
    {:reply, patch, state}
  end

  @impl true
  def handle_cast({:sync, map}, state) when is_map(map) do
    send(self(), :search)

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
    tasks =
      state.repo.comments
      |> Enum.group_by(& &1.file_path)
      |> Enum.map(fn {_file_path, comments} ->
        Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
          comments
          |> Enum.map(&Fastrepl.SemanticFunction.Modify.run!(state.repo, &1))
          |> Enum.reduce(state.repo, &Repository.Mutation.run!(&2, &1))
          |> Repository.Diff.from()
        end)
      end)

    callback = fn state, result ->
      state
      |> update_in([:repo, Access.key!(:diffs)], fn existing -> existing ++ result end)
      |> sync_with_views(:repo)
    end

    state =
      tasks
      |> Enum.reduce(state, fn task, acc ->
        update_in(acc, [:tasks, task.ref], fn _ -> %{callback: callback} end)
      end)

    {:noreply, state}
  end

  @impl true
  def handle_info(:search, state) do
    task =
      Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
        tools = [
          Fastrepl.Retrieval.Tool.SemanticSearch,
          Fastrepl.Retrieval.Tool.KeywordSearch
        ]

        context = %{
          root_path: state.repo.root_path,
          chunks: state.repo.chunks
        }

        chunks =
          tools
          |> Retrieval.Planner.from_issue(state.github_issue, state.github_issue_comments)
          |> Retrieval.Executor.run(context)

        existing_files_paths =
          state.repo.original_files
          |> Enum.map(& &1.path)
          |> Enum.uniq()

        chunks
        |> Enum.map(& &1.file_path)
        |> Enum.filter(&(&1 not in existing_files_paths))
        |> Enum.uniq()
        |> Enum.map(&Repository.File.from!(state.repo, &1))
      end)

    callback = fn state, files ->
      repo = files |> Enum.reduce(state.repo, &Repository.add_file!(&2, &1))

      state
      |> Map.put(:repo, repo)
      |> sync_with_views(:repo)
    end

    {:noreply, state |> update_in([:tasks, task.ref], fn _ -> %{callback: callback} end)}
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

    state = state |> Map.put(:messages, messages)

    if should_broadcast?(state, action) do
      {:noreply, state |> sync_with_views(:messages)}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info({:fetch_issue, data}, state) do
    github_issue = Github.get_issue!(data.repo_full_name, data.issue_number)
    github_issue_comments = Github.list_issue_comments!(data.repo_full_name, data.issue_number)

    state =
      state
      |> Map.put(:github_issue, github_issue)
      |> Map.put(:github_issue_comments, github_issue_comments)
      |> sync_with_views(:github_issue)

    {:noreply, state}
  end

  @impl true
  def handle_info(:clone_repo, state) do
    repo = state.repo.full_name |> Github.get_repo!()
    repo_sha = repo |> Github.get_latest_commit!()

    Task.Supervisor.start_child(Fastrepl.TaskSupervisor, fn ->
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

    state =
      state
      |> Map.put(:repo, %{state.repo | sha: repo_sha, description: repo.description})
      |> sync_with_views(:repo)

    {:noreply, state}
  end

  @impl true
  def handle_info({:post_clone_repo, root_path}, state) do
    paths =
      root_path
      |> FS.list_informative_files()
      |> Enum.map(&Path.relative_to(&1, root_path))

    chunks =
      root_path
      |> FS.list_informative_files()
      |> Enum.flat_map(&Retrieval.Chunker.chunk_file/1)

    Task.Supervisor.start_child(Fastrepl.TaskSupervisor, fn ->
      send(state.orchestrator_pid, {:repo_indexing, {:start, length(chunks)}})

      precompute_embeddings(chunks, fn n ->
        send(state.orchestrator_pid, {:repo_indexing, {:progress, n}})
      end)

      send(state.orchestrator_pid, {:repo_indexing, {:done, length(chunks)}})
    end)

    state =
      state
      |> Map.put(:repo, %{state.repo | root_path: root_path, paths: paths, chunks: chunks})
      |> sync_with_views(:repo)

    {:noreply, state}
  end

  @impl true
  def handle_info({:repo_indexing, {type, value}}, state) do
    state =
      case type do
        :start ->
          state |> Map.put(:indexing, %{state.indexing | progress: 0, total: value})

        :progress ->
          state |> update_in([:indexing, :progress], fn existing -> (existing || 0) + value end)

        :done ->
          state |> update_in([:indexing, :progress], fn _ -> value end)
      end

    {:noreply, state |> sync_with_views(:indexing)}
  end

  def handle_info({ref, result}, state) when is_reference(ref) do
    Process.demonitor(ref, [:flush])

    {data, tasks} = state.tasks |> pop_in([ref])
    state = state |> Map.put(:tasks, tasks)

    if data == nil do
      {:noreply, state}
    else
      {:noreply, state |> data.callback.(result)}
    end
  end

  def handle_info({:DOWN, ref, _, _, _}, state) do
    tasks = state.tasks |> pop_in([ref])
    {:noreply, state |> Map.put(:tasks, tasks)}
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

  defp precompute_embeddings(docs, cb) do
    docs
    |> Stream.map(&to_string/1)
    |> Stream.chunk_every(@precompute_batch_size)
    |> Stream.each(fn chunks ->
      Retrieval.Embedding.generate(chunks)
      cb.(length(chunks))
    end)
    |> Stream.run()
  end

  defp sync_with_views(state, key) when is_atom(key) do
    Phoenix.PubSub.broadcast(
      Fastrepl.PubSub,
      "thread:#{state.thread_id}",
      {:sync, %{key => state[key]}}
    )

    state
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
