defmodule Fastrepl.SessionManager do
  use GenServer, restart: :transient
  use Tracing

  alias Fastrepl.FS
  alias Fastrepl.Github
  alias Fastrepl.Retrieval
  alias Fastrepl.Sessions
  alias Fastrepl.Sessions.Ticket
  alias Fastrepl.Sessions.Comment
  alias Fastrepl.SemanticFunction.ApplyComments
  alias Fastrepl.SemanticFunction.PPWriter
  alias Fastrepl.SemanticFunction.CommentWriter

  def start_link(%{account_id: account_id, session_id: session_id} = args) do
    GenServer.start_link(__MODULE__, args, name: via_registry(session_id, account_id))
  end

  @impl true
  def init(%{
        ticket: %Ticket{type: :github} = ticket,
        account_id: account_id,
        session_id: session_id
      }) do
    Process.flag(:trap_exit, true)

    with %Github.App{} = app <-
           Github.find_app(account_id, ticket.github_repo_full_name),
         {:ok, session} <-
           Sessions.session_from(ticket, %{account_id: account_id, display_id: session_id}),
         token = Github.get_installation_token!(app.installation_id),
         {:ok, repository} =
           FS.Repository.from(ticket.github_repo_full_name, ticket.base_commit_sha, token) do
      updated_issue_body =
        ticket.github_issue.body
        |> update_fastrepl_section(
          "#### (Experimental) Try our [web app](#{FastreplWeb.Endpoint.url()}/session/#{session_id}) to find relevant snippets, write comments, or even create PR for simple fixes."
        )

      GitHub.Issues.update(
        ticket.github_repo.owner_name,
        ticket.github_repo.repo_name,
        ticket.github_issue.number,
        %{body: updated_issue_body},
        auth: token
      )

      send(self(), {:indexing, repository.root_path})

      state =
        Map.new()
        |> Map.put(:self, self())
        |> Map.put(:account_id, account_id)
        |> Map.put(:session, session)
        |> Map.put(:session_id, session_id)
        |> Map.put(:installation_id, app.installation_id)
        |> Map.put(:repository, repository)

      {:ok, state}
    else
      {:error, error} ->
        {:stop, error}
    end
  end

  @impl true
  def init(%{account_id: account_id, session_id: session_id}) do
    with {:ok, session} <-
           Sessions.session_from(%{account_id: account_id, display_id: session_id}),
         %Github.App{} = app <-
           Github.find_app(account_id, session.ticket.github_repo_full_name) do
      token = Github.get_installation_token!(app.installation_id)

      ticket = session.ticket |> Sessions.enrich_ticket(auth: token)
      session = session |> Map.put(:ticket, ticket)

      {:ok, repository} =
        FS.Repository.from(
          session.ticket.github_repo_full_name,
          session.ticket.base_commit_sha,
          token
        )

      state =
        Map.new()
        |> Map.put(:self, self())
        |> Map.put(:account_id, account_id)
        |> Map.put(:session, session)
        |> Map.put(:session_id, session_id)
        |> Map.put(:installation_id, app.installation_id)
        |> Map.put(:repository, repository)

      {:ok, state}
    end
  end

  @impl true
  def handle_call(:init_state, _from, state) do
    init_state = %{
      status: state.session.status,
      paths: state.repository.paths,
      original_files: state.repository.original_files,
      current_files: state.repository.current_files,
      comments: state.session.comments,
      patches: state.session.patches,
      ticket: state.session.ticket
    }

    {:reply, init_state, state}
  end

  @impl true
  def handle_call(:done, _from, state) do
    Sessions.update_session(state.session, %{status: :done})
    state = state |> sync_with_views(%{status: :done})
    {:stop, :normal, :ok, state}
  end

  @impl true
  def handle_call({:open_file, path}, _from, state) do
    case FS.Repository.open_file(state.repository, path) do
      {:ok, repo} ->
        file = FS.Repository.find_original_file(repo, path)
        {:reply, file, state |> Map.put(:repository, repo)}

      {:error, _} ->
        {:reply, nil, state}
    end
  end

  @impl true
  def handle_call({:open_file_for_edit, path}, _from, state) do
    original_file = FS.Repository.find_original_file(state.repository, path)
    current_file = FS.Repository.find_current_file(state.repository, path)
    {:reply, %{original_file: original_file, current_file: current_file}, state}
  end

  @impl true
  def handle_call({:update_file, file}, _from, state) do
    repo = FS.Repository.update_file(state.repository, file)

    state =
      state |> Map.put(:repository, repo)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:comments_create, [comment]}, _from, state) do
    {:ok, created} =
      comment
      |> Map.put("session_id", state.session.id)
      |> then(&Sessions.create_comment(%Comment{}, &1))

    next_comments = [created | state.session.comments]

    state =
      state
      |> sync_with_views(%{comments: next_comments})
      |> update_in([:session, Access.key(:comments)], fn _ -> next_comments end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:comments_delete, comments}, _from, state) do
    comments
    |> Enum.each(fn attrs ->
      attrs
      |> Map.put("session_id", state.session.id)
      |> Sessions.delete_comment()
    end)

    next_comments =
      state.session.comments
      |> Enum.reject(fn %{id: id} -> id in Enum.map(comments, & &1["id"]) end)

    state =
      state
      |> sync_with_views(%{comments: next_comments})
      |> update_in([:session, Access.key(:comments)], fn _ -> next_comments end)

    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:comments_update, [%{"id" => id} = attrs]}, _from, state) do
    i = Enum.find_index(state.session.comments, &(&1.id == id))

    state =
      if i do
        {:ok, updated} =
          state.session.comments
          |> Enum.at(i)
          |> Sessions.update_comment(attrs)

        next_comments = List.replace_at(state.session.comments, i, updated)

        state
        |> sync_with_views(%{comments: next_comments})
        |> update_in([:session, Access.key(:comments)], fn _ -> next_comments end)
      else
        state
      end

    {:reply, :ok, state}
  end

  @impl true
  def handle_call(:comments_share, _from, state) do
    token = Github.get_installation_token!(state.installation_id)

    comments =
      state.session.comments
      |> Enum.map(fn comment ->
        url =
          Github.URL.reference_file(
            state.session.ticket.github_repo.full_name,
            state.session.ticket.base_commit_sha,
            comment.file_path,
            comment.line_start,
            comment.line_end
          )

        "> #{url}\n\n#{comment.content}"
      end)
      |> Enum.join("\n<br/>\n")

    body =
      """
      These are some relevant comments for this issue:
      <br/>
      #{comments}

      ---

      _Generated by [Fastrepl](https://github.com/fastrepl/fastrepl) with help from maintainers._
      """

    result =
      GitHub.Issues.create_comment(
        state.session.ticket.github_repo.owner_name,
        state.session.ticket.github_repo.repo_name,
        state.session.ticket.github_issue_number,
        %{body: body},
        auth: token
      )

    case result do
      {:ok, %{html_url: url}} -> {:reply, {:ok, url}, state}
      _ -> {:reply, :error, state}
    end
  end

  @impl true
  def handle_call(:diffs_fetch, _from, state) do
    patches = FS.Patch.from(state.repository)
    {:reply, patches, state}
  end

  @impl true
  def handle_call(:pr_create, _from, state) do
    issue_number = state.session.ticket.github_issue_number
    repo_full_name = state.session.ticket.github_repo.full_name
    token = Github.get_installation_token!(state.installation_id)

    {:ok, pr_title} = PPWriter.run(state.session.patches)

    patch_paths = state.session.patches |> Enum.map(& &1.path)

    files =
      state.repository.current_files
      |> Enum.filter(fn file -> file.path in patch_paths end)

    result =
      Github.create_fastrepl_pr(
        state.session.ticket.github_repo,
        %{
          title: pr_title,
          body:
            "Resolves ##{issue_number}.\n\n_This PR is created with [Fastrepl](https://github.com/fastrepl/fastrepl)._\n",
          files: files,
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
    {existing_pid, state} = state |> Map.pop(:execution_pid)

    if existing_pid do
      Process.exit(existing_pid, :kill)
      send(state.self, {:update, :status, :idle})
      {:reply, :ok, state}
    else
      result =
        Task.Supervisor.start_child(Fastrepl.TaskSupervisor, fn ->
          send(state.self, {:update, :status, :run})

          repo =
            state.session.comments
            |> then(&ApplyComments.run(state.repository, &1))
            |> then(&FS.Mutation.apply(state.repository, &1))

          patches = FS.Patch.from(repo)

          send(state.self, {:update, :repository, repo})
          sync_with_views(state, %{current_files: repo.current_files})
          send(state.self, {:update, :patches, patches})

          # patches
          # |> Enum.map(fn patch -> Map.put(patch, :session_id, state.session.id) end)
          # |> Enum.each(&Sessions.create_patch/1)

          send(state.self, {:update, :execution_done, nil})
        end)

      case result do
        {:ok, pid} -> {:reply, :ok, state |> Map.put(:execution_pid, pid)}
        {:error, _} -> {:reply, :error, state}
      end
    end
  end

  @impl true
  def handle_info({:indexing, repo_root_path}, state) do
    Task.Supervisor.start_child(Fastrepl.TaskSupervisor, fn ->
      ctx =
        repo_root_path
        |> Retrieval.Context.from(state.repository.config)
        |> Retrieval.Context.add_tools([
          Retrieval.Tool.LookupFile,
          Retrieval.Tool.SemanticSearch,
          Retrieval.Tool.KeywordSearch
        ])

      send(state.self, {:update, :retrieval_ctx, ctx})
      precompute_embeddings(ctx.chunks)

      send(state.self, {:update, :status, :idle})
      # send(state.self, :retrieval)
    end)

    {:noreply, state}
  end

  @impl true
  def handle_info(:retrieval, state) do
    {ctx, plans} = Retrieval.Planner.run(state.retrieval_ctx, state.session.ticket.github_issue)
    {_, executor_result} = Retrieval.Executor.run(ctx, plans)

    results =
      executor_result
      |> Retrieval.Reranker.run()
      |> Retrieval.Result.fuse(min_distance: 10)
      |> Enum.take(3)

    comments =
      results
      |> CommentWriter.run(state.session.ticket.github_issue)
      |> List.flatten()
      |> Enum.map(&Map.put(&1, :session_id, state.session.id))
      |> Enum.map(&Sessions.create_comment(&1, %{}))
      |> Enum.map(fn {:ok, comment} -> comment end)

    repo =
      comments
      |> Enum.reduce(state.repository, fn comment, repo ->
        FS.Repository.add_file!(repo, comment.file_path)
      end)

    session = state.session |> Map.put(:comments, comments)

    state =
      state
      |> sync_with_views(%{comments: comments})
      |> sync_with_views(%{original_files: repo.original_files})
      |> sync_with_views(%{current_files: repo.current_files})
      |> Map.put(:session, session)
      |> Map.put(:repository, repo)

    {:noreply, state}
  end

  @impl true
  def handle_info({:update, key, value}, state) do
    state =
      case key do
        :status ->
          Sessions.update_session(state.session, %{status: value})

          state
          |> sync_with_views(%{status: value})
          |> update_in([:session, Access.key(:status)], fn _ -> value end)

        :execution_done ->
          state
          |> Map.put(:execution_pid, nil)
          |> sync_with_views(%{status: :idle})
          |> update_in([:session, Access.key(:status)], fn _ -> :idle end)

        :repository ->
          state |> Map.put(:repository, value)

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
    if state[:session_id] do
      Registry.unregister(registry_module(), state.session_id)
    end

    Sessions.update_session(state.session, %{status: state.session.status})

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

  defp update_fastrepl_section(target, content) do
    pattern = ~r/<details by="fastrepl">.*?<\/details>/s
    section = build_fastrepl_section(content)

    case Regex.run(pattern, target) do
      nil -> target <> "\n\n" <> section
      [_] -> Regex.replace(pattern, target, section)
    end
  end

  defp build_fastrepl_section(content) do
    """
    <details by="fastrepl">
    <summary>For maintainers</summary>

    #{content}
    ---
    _Generated by [Fastrepl](https://github.com/fastrepl/fastrepl)_
    </details>
    """
    |> String.trim()
  end

  defp via_registry(session_id, account_id) do
    {:via, Registry, {registry_module(), session_id, %{account_id: account_id}}}
  end

  defp registry_module() do
    Application.fetch_env!(:fastrepl, :session_manager_registry)
  end

  defp sync_with_views(state, map) when is_map(map) do
    broadcast(state.session_id, map)
    state
  end

  defp broadcast(session_id, data) do
    Phoenix.PubSub.broadcast(
      Fastrepl.PubSub,
      "session:#{session_id}",
      {:sync, data}
    )
  end
end
