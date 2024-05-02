defmodule Fastrepl.Orchestrator do
  use GenServer
  require Logger

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Repository

  alias Fastrepl.Retrieval.Grep
  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Chunker.Chunk
  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.QueryPlanner

  def start(%{thread_id: thread_id, repo_full_name: _, issue_number: _} = args) do
    GenServer.start(__MODULE__, args, name: via_registry(thread_id))
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

    send(state.orchestrator_pid, :init)

    {:ok, state}
  end

  @impl true
  def handle_cast({:submit, instruction}, state) do
    send(self(), {:planning, %{query: instruction}})
    {:noreply, state}
  end

  @impl true
  def handle_info(:init, state) do
    repo = state.repo.full_name |> Github.get_repo!()
    sha = repo |> Github.get_latest_commit!()

    issue = Github.get_issue!(repo.full_name, state.issue.number)
    comments = Github.list_issue_comments!(repo.full_name, state.issue.number)
    send(state.orchestrator_pid, {:planning, %{issue: issue, comments: comments}})

    root_path =
      Application.fetch_env!(:fastrepl, :clone_dir)
      |> Path.join("#{state.repo.full_name}-#{sha}")

    if not File.exists?(root_path) do
      Task.start(fn ->
        url = Github.URL.clone_without_token(state.repo.full_name)
        :ok = FS.git_clone(url, root_path)
        send(state.orchestrator_pid, {:init_vectordb, root_path})
      end)
    else
      send(state.orchestrator_pid, {:init_vectordb, root_path})
    end

    state =
      state
      |> Map.put(:repo, %{
        state.repo
        | root_path: root_path,
          sha: sha,
          description: repo.description
      })
      |> Map.put(:issue, %{state.issue | title: issue.title})

    sync_with_views(state.thread_id, %{repo: state.repo, issue: state.issue})
    {:noreply, state}
  end

  @impl true
  def handle_info({:init_vectordb, repo_root}, state) do
    if state.repo.vectordb_pid do
      Vectordb.stop(state.repo.vectordb_pid)
    end

    {:ok, vectordb_pid} = Vectordb.start(state.thread_id)

    chunks =
      repo_root
      |> FS.list_informative_files()
      |> Enum.flat_map(&Chunker.chunk_file/1)

    Task.start(fn ->
      sync_with_views(state.thread_id, %{indexing: {:start, length(chunks)}})

      Vectordb.ingest(
        vectordb_pid,
        chunks,
        fn n -> sync_with_views(state.thread_id, %{indexing: {:progress, n}}) end
      )

      sync_with_views(state.thread_id, %{indexing: {:done, length(chunks)}})
    end)

    {:noreply, state |> Map.put(:repo, %{state.repo | vectordb_pid: vectordb_pid})}
  end

  @impl true
  def handle_info({:planning, %{query: query}}, state) do
    task_id = Nanoid.generate()
    sync_with_views(state.thread_id, %{task: {task_id, "Query understanding: running..."}})

    Task.start(fn ->
      {:ok, plans} = QueryPlanner.from_query(query)
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
      {:ok, plans} = QueryPlanner.from_issue(issue, comments)
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
        {"semantic_search", %{"query" => query}} ->
          if state.repo.vectordb_pid do
            task_id = Nanoid.generate()

            sync_with_views(state.thread_id, %{
              task: {task_id, "Semantic search - '#{query}': running..."}
            })

            Task.start(fn ->
              chunks =
                state.repo.vectordb_pid
                |> Vectordb.query(query, top_k: 5, threshold: 0.3)
                |> Enum.map(
                  &%Chunk{&1 | file_path: Path.relative_to(&1.file_path, state.repo.root_path)}
                )

              send(state.orchestrator_pid, {:chunks, chunks})
              sync_with_views(state.thread_id, %{task: {task_id, "Semantic search - '#{query}'"}})
            end)
          end

        {"keyword_search", %{"query" => query}} ->
          task_id = Nanoid.generate()

          sync_with_views(state.thread_id, %{
            task: {task_id, "Keyword search - '#{query}': running..."}
          })

          Task.start(fn ->
            chunks =
              state.repo.root_path
              |> FS.list_informative_files()
              |> Enum.map(fn path ->
                lines = path |> Grep.grep_file(query)

                if Enum.empty?(lines),
                  do: nil,
                  else: Chunk.from(state.repo.root_path, path, lines)
              end)
              |> Enum.reject(&is_nil/1)

            send(state.orchestrator_pid, {:chunks, chunks})
            sync_with_views(state.thread_id, %{task: {task_id, "Keyword search - '#{query}'"}})
          end)

        {"search_file_path", %{"query" => query}} ->
          task_id = Nanoid.generate()

          sync_with_views(state.thread_id, %{
            task: {task_id, "Path search - '#{query}': running..."}
          })

          Task.start(fn ->
            chunks =
              state.repo.root_path
              |> FS.search_paths(query)
              |> Enum.map(&Chunk.from(state.repo.root_path, &1))

            send(state.orchestrator_pid, {:chunks, chunks})
            sync_with_views(state.thread_id, %{task: {task_id, "Path search - '#{query}'"}})
          end)
      end
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:chunks, chunks}, state) do
    chunks = Chunker.dedupe(state.repo.chunks ++ chunks)
    sync_with_views(state.thread_id, %{chunks: chunks})
    {:noreply, state |> Map.put(:repo, %{state.repo | chunks: chunks})}
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

  defp via_registry(id) do
    {:via, Registry, {registry_module(), id}}
  end

  defp registry_module() do
    Application.fetch_env!(:fastrepl, :orchestrator_registry)
  end

  defp sync_with_views(thread_id, state) when is_map(state) do
    Phoenix.PubSub.broadcast(Fastrepl.PubSub, "thread:#{thread_id}", {:sync, state})
  end
end
