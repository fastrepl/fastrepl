defmodule Fastrepl.Orchestrator do
  use GenServer
  require Logger

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Repository

  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Planner

  alias Fastrepl.Tool.KeywordSearch
  alias Fastrepl.Tool.SemanticSearch
  alias Fastrepl.Tool.PathSearch

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
      |> Map.put(:issue, %{title: "", number: args.issue_number})
      |> Map.put(:current_step, "Initialization")

    send(state.orchestrator_pid, :fetch_issue)
    send(state.orchestrator_pid, :clone_repo)

    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, %{repo: state.repo, issue: state.issue, current_step: state.current_step}, state}
  end

  @impl true
  def handle_cast({:submit, instruction}, state) do
    send(self(), {:planning, %{query: instruction}})
    {:noreply, state}
  end

  @impl true
  def handle_cast({:sync, map}, state) when is_map(map) do
    state = map |> Enum.reduce(state, fn {k, v}, acc -> Map.put(acc, k, v) end)
    {:noreply, state}
  end

  @impl true
  def handle_info(:fetch_issue, state) do
    issue = Github.get_issue!(state.repo.full_name, state.issue.number)
    comments = Github.list_issue_comments!(state.repo.full_name, state.issue.number)

    state = state |> Map.put(:issue, %{state.issue | title: issue.title})

    sync_with_views(state.thread_id, %{issue: state.issue})
    send(state.orchestrator_pid, {:planning, %{issue: issue, comments: comments}})

    {:noreply, state}
  end

  @impl true
  def handle_info(:clone_repo, state) do
    repo = state.repo.full_name |> Github.get_repo!()
    sha = repo |> Github.get_latest_commit!()

    root_path =
      Application.fetch_env!(:fastrepl, :clone_dir)
      |> Path.join("#{state.repo.full_name}-#{sha}")

    if not File.exists?(root_path) do
      Task.start(fn ->
        url = Github.URL.clone_without_token(state.repo.full_name)
        :ok = FS.git_clone(url, root_path)
        send(state.orchestrator_pid, {:post_clone_repo, root_path})
      end)
    else
      send(state.orchestrator_pid, {:post_clone_repo, root_path})
    end

    state =
      state
      |> Map.put(:repo, %{
        state.repo
        | root_path: root_path,
          sha: sha,
          description: repo.description
      })

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
      send(state.orchestrator_pid, {:indexing, {:start, length(chunks)}})

      Vectordb.ingest(
        vectordb_pid,
        chunks,
        fn n -> send(state.orchestrator_pid, {:indexing, {:progress, n}}) end
      )

      send(state.orchestrator_pid, {:indexing, {:done, length(chunks)}})
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
  def handle_info({:planning, %{query: query}}, state) do
    task_id = Nanoid.generate()
    sync_with_views(state.thread_id, %{task: {task_id, "Query understanding: running..."}})

    Task.start(fn ->
      {:ok, plans} = Planner.from_query(query)
      send(state.orchestrator_pid, {:run_plans, plans})
      sync_with_views(state.thread_id, %{task: {task_id, "Query understanding"}})
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:planning, %{issue: issue, comments: comments}}, state) do
    task_id = Nanoid.generate()
    sync_with_views(state.thread_id, %{task: {task_id, "Issue understanding: running..."}})

    Task.start(fn ->
      {:ok, plans} = Planner.from_issue(issue, comments)
      send(state.orchestrator_pid, {:run_plans, plans})
      sync_with_views(state.thread_id, %{task: {task_id, "Issue understanding"}})
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:run_plans, plans}, state) do
    plans
    |> Enum.each(fn plan ->
      case plan do
        {"semantic_search", %{"query" => query} = args} ->
          if state.repo.vectordb_pid do
            task_id = Nanoid.generate()

            sync_with_views(state.thread_id, %{
              task: {task_id, "Semantic search - '#{query}': running..."}
            })

            Task.start(fn ->
              chunks =
                SemanticSearch.run(args, %{
                  vectordb_pid: state.repo.vectordb_pid,
                  root_path: state.repo.root_path
                })

              send(state.orchestrator_pid, {:chunks, chunks})
              sync_with_views(state.thread_id, %{task: {task_id, "Semantic search - '#{query}'"}})
            end)
          end

        {"keyword_search", %{"query" => query} = args} ->
          task_id = Nanoid.generate()

          sync_with_views(state.thread_id, %{
            task: {task_id, "Keyword search - '#{query}': running..."}
          })

          Task.start(fn ->
            chunks = KeywordSearch.run(args, %{root_path: state.repo.root_path})
            send(state.orchestrator_pid, {:chunks, chunks})
            sync_with_views(state.thread_id, %{task: {task_id, "Keyword search - '#{query}'"}})
          end)

        {"path_search", %{"query" => query} = args} ->
          task_id = Nanoid.generate()

          sync_with_views(state.thread_id, %{
            task: {task_id, "Path search - '#{query}': running..."}
          })

          Task.start(fn ->
            chunks = PathSearch.run(args, %{root_path: state.repo.root_path})
            send(state.orchestrator_pid, {:chunks, chunks})
            sync_with_views(state.thread_id, %{task: {task_id, "Path search - '#{query}'"}})
          end)
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:indexing, {type, value}}, state) do
    state =
      case type do
        :start ->
          state |> Map.put(:repo, %{state.repo | indexing_progress: 0, indexing_total: value})

        :progress ->
          state
          |> Map.put(:repo, %{
            state.repo
            | indexing_progress: (state.repo.indexing_progress || 0) + value
          })

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
      |> Map.put(
        :files,
        Enum.map(chunks, fn chunk -> %{path: chunk.file_path, content: chunk.content} end)
      )

    sync_with_views(state.thread_id, %{repo: repo})
    {:noreply, state |> Map.put(:repo, repo)}
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
end
