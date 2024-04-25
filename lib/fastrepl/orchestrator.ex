defmodule Fastrepl.Orchestrator do
  use GenServer
  require Logger

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Vectordb

  def start(%{thread_id: thread_id, repo_full_name: _} = args) do
    GenServer.start(__MODULE__, args, name: via_registry(thread_id))
  end

  @impl true
  def init(args) do
    Process.flag(:trap_exit, true)

    sha = Github.get_repo!(args.repo_full_name) |> Github.get_latest_commit()
    repo_root = Path.join("./tmp/repos", "#{args.repo_full_name}-#{sha}")

    if not File.exists?(repo_root) do
      send(self(), {:init_repo, args.repo_full_name})
    else
      send(self(), {:init_vectordb, repo_root})
    end

    state =
      %{}
      |> Map.put(:orchestrator_pid, self())
      |> Map.put(:thread_id, args.thread_id)
      |> Map.put(:repo_full_name, args.repo_full_name)
      |> Map.put(:repo_root, repo_root)

    {:ok, state}
  end

  @impl true
  def handle_info({:init_repo, repo_full_name}, state) do
    Task.start(fn ->
      url = Github.URL.clone_without_token(repo_full_name)
      FS.git_clone(url, state.repo_root)

      send(state.orchestrator_pid, {:init_vectordb, state.repo_root})
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info({:init_vectordb, repo_root}, state) do
    {:ok, _vectordb_pid} = Vectordb.start(state.thread_id)

    chunks =
      repo_root
      |> FS.list_informative_files()
      |> Enum.flat_map(&Chunker.chunk_file/1)

    IO.inspect(chunks)
    # Vectordb.ingest(vectordb_pid, chunks)

    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    Registry.unregister(registry_module(), state.thread_id)
    :ok
  end

  defp via_registry(id) do
    {:via, Registry, {registry_module(), id}}
  end

  defp registry_module() do
    Application.fetch_env!(:fastrepl, :orchestrator_registry)
  end
end
