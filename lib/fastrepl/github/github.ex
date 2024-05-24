defmodule Fastrepl.Github do
  import Ecto.Query, warn: false
  alias Fastrepl.Repo

  alias Fastrepl.Accounts.Account
  alias Fastrepl.Github

  def add_app(%Account{} = account, attrs \\ %{}) do
    %Github.App{}
    |> Github.App.changeset(attrs)
    |> Ecto.Changeset.put_assoc(:account, account)
    |> Repo.insert()
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

  def get_installation_token!(installation_id) do
    {:ok, %{token: token}} =
      GitHub.Apps.create_installation_access_token(
        installation_id,
        %{},
        auth: GitHub.app(:fastrepl)
      )

    token
  end
end
