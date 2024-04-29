defmodule Fastrepl.Orchestrator do
  use GenServer
  require Logger

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Chunker.Chunk

  def start(%{thread_id: thread_id, repo_full_name: _} = args) do
    GenServer.start(__MODULE__, args, name: via_registry(thread_id))
  end

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    send(self(), :init_repo)

    state =
      %{}
      |> Map.put(:orchestrator_pid, self())
      |> Map.put(:thread_id, args.thread_id)
      |> Map.put(:repo_full_name, args.repo_full_name)

    {:ok, state}
  end

  @impl true
  def handle_call({:submit, %{instruction: instruction}}, _from, state) do
    if state[:vectordb_pid] do
      Task.start(fn ->
        chunks =
          state.vectordb_pid
          |> Vectordb.query(instruction, top_k: 5, threshold: 0.3)
          |> Enum.map(&%Chunk{&1 | file_path: Path.relative_to(&1.file_path, state.repo_root)})

        sync_with_views(state.thread_id, %{chunks: chunks})
      end)
    end

    {:reply, %{}, state}
  end

  @impl true
  def handle_info(:init_repo, state) do
    sha = Github.get_repo!(state.repo_full_name) |> Github.get_latest_commit()

    repo_root =
      Application.fetch_env!(:fastrepl, :clone_dir)
      |> Path.join("#{state.repo_full_name}-#{sha}")

    if not File.exists?(repo_root) do
      Task.start(fn ->
        url = Github.URL.clone_without_token(state.repo_full_name)
        :ok = FS.git_clone(url, repo_root)
        send(state.orchestrator_pid, {:init_vectordb, repo_root})
      end)
    else
      send(state.orchestrator_pid, {:init_vectordb, repo_root})
    end

    state =
      state
      |> Map.put(:repo_root, repo_root)
      |> Map.put(:repo_sha, sha)

    {:noreply, state}
  end

  @impl true
  def handle_info({:init_vectordb, repo_root}, state) do
    if state[:vectordb_pid] do
      Vectordb.stop(state.vectordb_pid)
    end

    {:ok, vectordb_pid} = Vectordb.start(state.thread_id)

    chunks =
      repo_root
      |> FS.list_informative_files()
      |> Enum.flat_map(&Chunker.chunk_file/1)

    Task.start(fn ->
      Vectordb.ingest(vectordb_pid, chunks)
    end)

    {:noreply, state |> Map.put(:vectordb_pid, vectordb_pid)}
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

    if state[:vectordb_pid] do
      Vectordb.stop(state.vectordb_pid)
    end

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
