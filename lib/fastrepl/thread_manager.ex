defmodule Fastrepl.ThreadManager do
  use GenServer, restart: :transient
  use Tracing
  require Logger

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Retrieval
  alias Fastrepl.Sessions.Ticket
  alias Fastrepl.Sessions.Session
  alias Fastrepl.Sessions.Comment
  alias Fastrepl.FS

  def start_link(%{account_id: account_id, thread_id: thread_id} = args) do
    GenServer.start_link(__MODULE__, args, name: via_registry(thread_id, account_id))
  end

  @impl true
  def init(%{
        account_id: account_id,
        thread_id: thread_id,
        installation_id: installation_id,
        repo_full_name: repo_full_name,
        issue_number: issue_number
      }) do
    Process.flag(:trap_exit, true)

    token = Github.get_installation_token!(installation_id)
    repo = Github.Repo.from!(repo_full_name, auth: token)
    issue = Github.Issue.from!(repo_full_name, issue_number, auth: token)

    {:ok, %{id: comment_id}} =
      Github.Issue.Comment.create(
        repo_full_name,
        issue_number,
        """
        We have just started processing your issue.

        You can check the progress here: #{FastreplWeb.Endpoint.url()}/thread/#{thread_id}
        """,
        auth: token
      )

    ticket = %Ticket{
      type: :github,
      github_repo_full_name: repo_full_name,
      github_repo_sha: repo.default_branch_head,
      github_issue_number: issue_number,
      github_repo: repo,
      github_issue: issue
    }

    session = %Session{
      status: :init_0,
      ticket: ticket,
      display_id: thread_id,
      github_issue_comment_id: comment_id,
      comments: []
    }

    state =
      Map.new()
      |> Map.put(:self, self())
      |> Map.put(:account_id, account_id)
      |> Map.put(:github_token, token)
      |> Map.put(:session, session)
      |> Map.put(:thread_id, thread_id)

    send(state.self, :prepare_repo)
    {:ok, state}
  end

  @impl true
  def handle_call(:init_state, _from, state) do
    init_state = %{
      paths: state.repository.paths,
      files: state.repository.original_files,
      comments: state.session.comments,
      status: state.session.status,
      github_issue: state.session.ticket.github_issue,
      github_repo: state.session.ticket.github_repo
    }

    {:reply, init_state, state}
  end

  @impl true
  def handle_call({:file_add, path}, _from, state) do
    {repo, file} = FS.Repository.add_file!(state.repository, path)

    state =
      state
      |> sync_with_views(%{files: repo.original_files})
      |> Map.put(:repository, repo)

    {:reply, file, state}
  end

  @impl true
  def handle_call({:comment_add, comment}, _from, state) do
    comment =
      comment
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> then(&struct(Comment, &1))

    new_comments = [comment | state.session.comments]

    state =
      state
      |> sync_with_views(%{comments: new_comments})
      |> update_in([:session, Access.key(:comments)], fn _ -> new_comments end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:execute, _from, state) do
    Task.Supervisor.start_child(Fastrepl.TaskSupervisor, fn ->
      send(state.self, {:update, :status, :execute_4})

      Process.sleep(2000)
      send(state.self, {:update, :status, :start_3})
    end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_info(:prepare_repo, state) do
    Task.Supervisor.start_child(Fastrepl.TaskSupervisor, fn ->
      send(state.self, {:update, :status, :clone_1})

      {:ok, repository} =
        FS.Repository.from(
          state.session.ticket.github_repo_full_name,
          state.session.ticket.github_repo_sha,
          state.github_token
        )

      send(state.self, {:update, :repository, repository})
      send(state.self, {:update, :status, :index_2})

      ctx =
        repository.root_path
        |> Retrieval.Context.from()
        |> Retrieval.Context.add_tools([
          Retrieval.Tool.SemanticSearch,
          Retrieval.Tool.KeywordSearch
        ])

      send(state.self, {:update, :retrieval_ctx, ctx})
      precompute_embeddings(ctx.chunks)

      send(state.self, {:update, :status, :start_3})
      send(state.self, :retrieval)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(:retrieval, state) do
    # {ctx, plans} = Retrieval.Planner.run(state.retrieval_ctx, state.session.ticket.github_issue)
    # {_, executor_result} = Retrieval.Executor.run(ctx, plans)

    # results =
    #   executor_result
    #   |> Retrieval.Reranker.run()
    #   |> Retrieval.Result.fuse(min_distance: 10)
    #   |> Enum.take(3)

    # IO.inspect(results)

    {:noreply, state}
  end

  @impl true
  def handle_info({:update, key, value}, state) do
    state =
      case key do
        :status ->
          state
          |> sync_with_views(%{status: value})
          |> update_in([:session, Access.key(:status)], fn _ -> value end)

        :repository ->
          state
          |> sync_with_views(%{paths: value.paths})
          |> Map.put(:repository, value)

        :retrieval_ctx ->
          state |> Map.put(:retrieval_ctx, value)

        _ ->
          state
      end

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

  defp sync_with_views(state, map) when is_map(map) do
    broadcast(state.thread_id, map)
    state
  end

  defp broadcast(thread_id, data) do
    Phoenix.PubSub.broadcast(
      Fastrepl.PubSub,
      "thread:#{thread_id}",
      {:sync, data}
    )
  end
end
