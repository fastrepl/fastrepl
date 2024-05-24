defmodule Fastrepl.ThreadManager do
  use GenServer, restart: :transient

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Retrieval

  def start_link(%{account_id: account_id, thread_id: thread_id} = args) do
    GenServer.start_link(__MODULE__, args, name: via_registry(thread_id, account_id))
  end

  @impl true
  def init(%{
        account_id: account_id,
        thread_id: thread_id,
        repo_full_name: repo_full_name,
        issue_number: issue_number,
        installation_id: installation_id
      }) do
    Process.flag(:trap_exit, true)

    token = Github.get_installation_token!(installation_id)
    repo = Github.Repo.from!(repo_full_name, auth: token)
    app = Github.find_app(account_id, repo_full_name)

    state =
      Map.new()
      |> Map.put(:self, self())
      |> Map.put(:thread_id, thread_id)
      |> Map.put(:github_repo, repo)
      |> Map.put(:github_app, app)

    Github.Issue.Comment.create(
      repo_full_name,
      issue_number,
      """
      We have just started processing your issue.

      You can check the progress here: #{FastreplWeb.Endpoint.url()}/thread/#{thread_id}
      """,
      auth: token
    )

    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_info(:prepare_repo, state) do
    Task.Supervisor.start_child(Fastrepl.TaskSupervisor, fn ->
      {:ok, root_path} =
        state.github_repo.full_name
        |> Github.URL.clone_with_token(state.github_app.installation_id)
        |> FS.clone(state.github_repo)

      ctx =
        root_path
        |> Retrieval.Context.from()
        |> Retrieval.Context.add_tools([
          Retrieval.Tool.SemanticSearch,
          Retrieval.Tool.KeywordSearch
        ])

      send(state.self, {:set, %{root_path: root_path, retrieval_ctx: ctx}})
      precompute_embeddings(ctx.chunks)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(:retrieve, state) do
    {:noreply, state}
  end

  @impl true
  def handle_info({:set, data}, state) do
    state = data |> Enum.reduce(state, fn {k, v}, acc -> Map.put(acc, k, v) end)
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

  defp precompute_embeddings(docs, cb \\ fn _chunks -> :ok end) do
    docs
    |> Stream.map(&to_string/1)
    |> Stream.chunk_every(60)
    |> Stream.each(fn chunks ->
      cb.(chunks)
      Retrieval.Embedding.generate(chunks)
    end)
    |> Stream.run()
  end

  defp via_registry(thread_id, account_id) do
    {:via, Registry, {registry_module(), thread_id, %{account_id: account_id}}}
  end

  defp registry_module() do
    Application.fetch_env!(:fastrepl, :thread_manager_registry)
  end
end
