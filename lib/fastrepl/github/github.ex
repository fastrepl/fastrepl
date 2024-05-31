defmodule Fastrepl.Github do
  import Ecto.Query, warn: false
  alias Fastrepl.Repo

  alias Fastrepl.Github
  alias Fastrepl.Accounts.Account

  def add_app(attrs) do
    %Github.App{}
    |> Github.App.changeset(attrs)
    |> Repo.insert()
  end

  def update_app(%Github.App{} = app, attrs) do
    app
    |> Github.App.changeset(attrs)
    |> Repo.update()
  end

  def find_app(account_id, repo_full_name) do
    from(
      app in Github.App,
      where: app.account_id == ^account_id and ^repo_full_name in app.repo_full_names
    )
    |> Repo.one()
  end

  def get_app_by_installation_id(installation_id) do
    from(app in Github.App, where: app.installation_id == ^installation_id)
    |> Repo.one()
  end

  def delete_app_by_installation_id(installation_id) do
    from(app in Github.App, where: app.installation_id == ^installation_id)
    |> Repo.delete_all()
  end

  def set_repos(%Github.App{} = app, names) do
    app
    |> Github.App.changeset(%{repo_full_names: names})
    |> Repo.update()
  end

  def list_apps(%Account{} = account) do
    from(app in Github.App, where: app.account_id == ^account.id)
    |> Repo.all()
  end

  def list_installed_repos(%Account{} = account) do
    from(app in Github.App, where: app.account_id == ^account.id)
    |> Repo.all()
    |> Enum.flat_map(& &1.repo_full_names)
  end

  def get_installation_token(installation_id) do
    result =
      GitHub.Apps.create_installation_access_token(
        installation_id,
        %{},
        auth: GitHub.app(:fastrepl)
      )

    case result do
      {:ok, %{token: token}} -> {:ok, token}
      others -> {:error, others}
    end
  end

  def get_installation_token!(installation_id) do
    {:ok, token} = get_installation_token(installation_id)
    token
  end

  def create_fastrepl_pr(
        %Github.Repo{} = repo,
        %{title: title, body: body, files: files, auth: auth}
      ) do
    with {:ok, target_branch} = create_fastrepl_branch(repo, %{auth: auth}),
         :ok <-
           make_commits_to_branch(
             repo,
             %{files: files, target_branch: target_branch, auth: auth}
           ),
         {:ok, %{number: pr_number}} <-
           GitHub.Pulls.create(
             repo.owner_name,
             repo.repo_name,
             %{
               title: title,
               body: body,
               head: target_branch,
               base: repo.base_branch,
               maintainer_can_modify: true,
               draft: false
             },
             auth: auth
           ),
         {:ok, _} <-
           GitHub.Issues.add_labels(
             repo.owner_name,
             repo.repo_name,
             pr_number,
             %{labels: ["fastrepl"]},
             auth: auth
           ) do
      {:ok, pr_number}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp create_fastrepl_branch(%Github.Repo{} = repo, %{auth: auth} = args) do
    id = Enum.map(1..6, fn _ -> Enum.random(0..9) end) |> Enum.join()
    branch_name = "fastrepl/#{id}"

    result =
      GitHub.Git.create_ref(
        repo.owner_name,
        repo.repo_name,
        %{ref: "refs/heads/#{branch_name}", sha: repo.base_commit},
        auth: auth
      )

    case result do
      {:ok, _} -> {:ok, branch_name}
      {:error, %GitHub.Error{code: 422}} -> create_fastrepl_branch(repo, args)
      {:error, error} -> {:error, error}
    end
  end

  defp make_commits_to_branch(
         %Github.Repo{} = repo,
         %{files: files, target_branch: target_branch, auth: auth}
       ) do
    files
    |> Enum.map(fn file ->
      case GitHub.Repos.get_content(
             repo.owner_name,
             repo.repo_name,
             file.path,
             ref: repo.base_commit,
             auth: auth
           ) do
        {:ok, %{sha: sha}} -> {file, sha}
        _ -> {file, nil}
      end
    end)
    |> Enum.each(fn {file, sha} ->
      shared_args = %{
        content: Base.encode64(file.content),
        sha: sha,
        branch: target_branch
      }

      args =
        if sha == nil do
          Map.put(shared_args, :message, "create #{file.path}")
        else
          Map.put(shared_args, :message, "modify #{file.path}")
        end

      GitHub.Repos.create_or_update_file_contents(
        repo.owner_name,
        repo.repo_name,
        file.path,
        args,
        auth: auth
      )
    end)

    :ok
  end
end
