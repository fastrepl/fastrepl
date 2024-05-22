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

  def delete_app(%Github.App{} = app) do
    Repo.delete(app)
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
