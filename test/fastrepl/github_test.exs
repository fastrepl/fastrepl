defmodule Fastrepl.GithubTest do
  use Fastrepl.DataCase

  import Fastrepl.UsersFixtures
  import Fastrepl.AccountsFixtures

  alias Fastrepl.Github

  describe "github" do
    test "add_app/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      {:ok, app} = Github.add_app(account, %{installation_id: "123"})
      assert app.installation_id == "123"
      assert app.account_id == account.id
    end

    test "delete_app/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      {:ok, app} = Github.add_app(account, %{installation_id: "123"})

      assert Github.list_apps(account) |> length() == 1
      {:ok, _} = Github.delete_app(app)
      assert Github.list_apps(account) |> length() == 0
    end

    test "set_repos/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      {:ok, app} = Github.add_app(account, %{installation_id: "123"})
      assert app.repo_full_names == []
      {:ok, app} = Github.set_repos(app, ["fastrepl/fastrepl"])
      assert app.repo_full_names == ["fastrepl/fastrepl"]
    end

    test "list_apps/1" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      {:ok, _} = Github.add_app(account, %{installation_id: "123"})
      {:ok, _} = Github.add_app(account, %{installation_id: "456"})
      assert Github.list_apps(account) |> length() == 2
    end
  end
end
