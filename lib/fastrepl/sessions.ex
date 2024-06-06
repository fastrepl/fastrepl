defmodule Fastrepl.Sessions do
  import Ecto.Query, warn: false
  alias Fastrepl.Repo

  alias Fastrepl.Github
  alias Fastrepl.FS.Patch
  alias Fastrepl.Accounts.Account

  alias Fastrepl.Sessions.Ticket
  alias Fastrepl.Sessions.Comment
  alias Fastrepl.Sessions.Session

  def find_active_session(session_display_id) do
    registry = Application.fetch_env!(:fastrepl, :session_manager_registry)

    case Registry.select(registry, [{{session_display_id, :"$1", :_}, [], [:"$1"]}]) do
      [pid] -> pid
      [] -> nil
    end
  end

  def list_sessions(%Account{} = account, opts \\ []) do
    limit = Keyword.get(opts, :limit, nil)

    query =
      from s in Session,
        where: s.account_id == ^account.id,
        preload: [:ticket],
        order_by: [desc: s.inserted_at]

    query =
      if limit do
        from q in query, limit: ^limit
      else
        query
      end

    Repo.all(query)
  end

  def list_comments(%Session{} = session) do
    Repo.all(from c in Comment, where: c.session_id == ^session.id)
  end

  def ticket_from(
        %{
          github_issue_number: github_issue_number,
          github_repo_full_name: github_repo_full_name
        } = attrs,
        opts \\ []
      ) do
    ticket =
      Repo.one(
        from t in Ticket,
          where:
            t.github_issue_number == ^github_issue_number and
              t.github_repo_full_name == ^github_repo_full_name
      )

    with {:ok, repo} <- Github.Repo.from(github_repo_full_name, opts),
         {:ok, issue} <- Github.Issue.from(github_repo_full_name, github_issue_number, opts) do
      if ticket != nil do
        {:ok, ticket |> Map.merge(%{github_repo: repo, github_issue: issue})}
      else
        attrs = Map.merge(%{base_commit_sha: repo.default_branch_head}, attrs)

        %Ticket{github_repo: repo, github_issue: issue}
        |> Ticket.changeset(attrs)
        |> Repo.insert()
      end
    end
  end

  def enrich_ticket(ticket, opts \\ [])

  def enrich_ticket(%Ticket{type: :github} = ticket, opts) do
    %{
      github_repo_full_name: repo_name,
      github_issue_number: issue_number
    } = ticket

    with {:ok, repo} <- Github.Repo.from(repo_name, opts),
         {:ok, issue} <- Github.Issue.from(repo_name, issue_number, opts) do
      %Ticket{ticket | github_repo: repo, github_issue: issue}
    else
      _ -> ticket
    end
  end

  def enrich_ticket(ticket, _opts), do: ticket

  def session_from(%Ticket{} = ticket, attrs) do
    case Session |> Repo.get_by(attrs) do
      nil ->
        %Session{}
        |> Session.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:ticket, ticket)
        |> Ecto.Changeset.put_assoc(:comments, [])
        |> Ecto.Changeset.put_assoc(:patches, [])
        |> Repo.insert()

      session ->
        session =
          session
          |> Repo.preload([:comments, :patches])
          |> Map.put(:ticket, ticket)

        {:ok, session}
    end
  end

  def session_from(%{account_id: account_id, display_id: display_id}) do
    case Session |> Repo.get_by(account_id: account_id, display_id: display_id) do
      nil ->
        {:error, :not_found}

      session ->
        session = session |> Repo.preload([:ticket, :comments, :patches])
        {:ok, session}
    end
  end

  def find_session(attrs) do
    Session |> Repo.get_by(attrs)
  end

  def find_sessions(%{
        github_repo_full_name: repo_name,
        github_issue_number: issue_number
      }) do
    q =
      from s in Session,
        join: t in assoc(s, :ticket),
        where: t.github_repo_full_name == ^repo_name and t.github_issue_number == ^issue_number,
        preload: [ticket: t]

    Repo.all(q)
  end

  def update_session(%Session{} = session, attrs) do
    case Repo.get_by(Session, id: session.id) do
      nil ->
        {:error, "not found"}

      session ->
        session
        |> Session.changeset(attrs)
        |> Repo.update()
    end
  end

  def create_patch(%Patch{} = patch, attrs \\ %{}) do
    patch
    |> Patch.changeset(attrs)
    |> Repo.insert()
  end

  def create_comment(%Comment{} = comment, attrs \\ %{}) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.insert()
  end

  def delete_comment(%{id: id}) do
    Comment
    |> Repo.get(id)
    |> Repo.delete()
  end

  def delete_comment(%{"id" => id}) do
    Comment
    |> Repo.get(id)
    |> Repo.delete()
  end

  def update_comment(%Comment{} = comment, attrs) do
    comment
    |> Comment.changeset(attrs)
    |> Repo.update()
  end
end
