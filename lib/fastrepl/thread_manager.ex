defmodule Fastrepl.ThreadManager do
  use GenServer, restart: :transient
  use Tracing

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Retrieval
  alias Fastrepl.Sessions
  alias Fastrepl.Sessions.Ticket
  alias Fastrepl.Sessions.Comment
  alias Fastrepl.SemanticFunction.Modify
  alias Fastrepl.SemanticFunction.PPWriter

  def start_link(%{account_id: account_id, thread_id: thread_id} = args) do
    GenServer.start_link(__MODULE__, args, name: via_registry(thread_id, account_id))
  end

  @impl true
  def init(%{account_id: account_id, thread_id: thread_id, ticket: %Ticket{} = ticket}) do
    Process.flag(:trap_exit, true)

    with %Github.App{} = app <-
           Github.find_app(account_id, ticket.github_repo_full_name),
         {:ok, session} <-
           Sessions.session_from(ticket, %{account_id: account_id, display_id: thread_id}) do
      send(self(), :prepare_repo)

      if session.status == :init_0 do
        token = Github.get_installation_token!(app.installation_id)

        {:ok, %{id: _comment_id}} =
          Github.Issue.Comment.create(
            ticket.github_repo_full_name,
            ticket.github_issue_number,
            """
            We have just started processing your issue.

            You can check the progress here: #{FastreplWeb.Endpoint.url()}/thread/#{thread_id}
            """,
            auth: token
          )
      end

      state =
        Map.new()
        |> Map.put(:self, self())
        |> Map.put(:account_id, account_id)
        |> Map.put(:session, session)
        |> Map.put(:thread_id, thread_id)
        |> Map.put(:installation_id, app.installation_id)

      {:ok, state}
    else
      {:error, error} ->
        {:stop, error}
    end
  end

  @impl true
  def handle_call(:init_state, _from, state) do
    init_state = %{
      status: state.session.status,
      paths: state.repository.paths,
      files: state.repository.original_files,
      comments: state.session.comments,
      patches: state.session.patches,
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
  def handle_call({:comment_add, attrs}, _from, state) do
    comment = Sessions.create_comment(attrs)
    new_comments = [comment | state.session.comments]

    state =
      state
      |> sync_with_views(%{comments: new_comments})
      |> update_in([:session, Access.key(:comments)], fn _ -> new_comments end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:comments_update, comments}, _from, state) do
    comments =
      comments
      |> Enum.map(fn comment ->
        comment
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
        |> then(&struct(Comment, &1))
      end)

    state =
      state
      |> sync_with_views(%{comments: comments})
      |> update_in([:session, Access.key(:comments)], fn _ -> comments end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:pr_create, _from, state) do
    issue_number = state.session.ticket.github_issue_number
    repo_full_name = state.session.ticket.github_repo.full_name
    token = Github.get_installation_token!(state.installation_id)

    {:ok, pr_title} = PPWriter.run(state.session.patches)

    result =
      Github.create_fastrepl_pr(
        state.session.ticket.github_repo,
        %{
          title: pr_title,
          body:
            "Resolves ##{issue_number}.\n\n_This PR is created with [Fastrepl](https://github.com/fastrepl/fastrepl)._\n",
          files: state.repository.current_files,
          auth: token
        }
      )

    reply =
      case result do
        {:ok, pr_number} -> {:ok, "https://github.com/#{repo_full_name}/pull/#{pr_number}"}
        _ -> {:error, "error"}
      end

    {:reply, reply, state}
  end

  @impl true
  def handle_call(:execute, _from, state) do
    Task.Supervisor.start_child(Fastrepl.TaskSupervisor, fn ->
      send(state.self, {:update, :status, :execute_4})

      result = Modify.run(state.repository, Enum.at(state.session.comments, 0))

      case result do
        {:ok, mut} ->
          repo = FS.Mutation.apply(state.repository, mut)
          patches = FS.Patch.from(repo)
          send(state.self, {:update, :patches, patches})
          send(state.self, {:update, :repository, repo})

        error ->
          IO.inspect(error)
      end

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
          state.session.ticket.base_commit_sha,
          Github.get_installation_token!(state.installation_id)
        )

      sync_with_views(state, %{paths: repository.paths})
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
          |> Map.put(:repository, value)

        :patches ->
          state
          |> sync_with_views(%{patches: value})
          |> update_in([:session, Access.key(:patches)], fn _ -> value end)

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
