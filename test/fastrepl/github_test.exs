defmodule Fastrepl.GithubTest do
  use Fastrepl.DataCase

  import Fastrepl.UsersFixtures
  import Fastrepl.AccountsFixtures

  alias Fastrepl.Github

  describe "github" do
    test "add_app/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      {:ok, app} = Github.add_app(%{installation_id: 123, account_id: account.id})
      assert app.installation_id == 123
      assert app.account_id == account.id
    end

    test "find_app/1" do
      account = user_fixture() |> account_fixture(%{name: "personal"})

      {:ok, _} =
        Github.add_app(%{
          installation_id: 123,
          repo_full_names: ["1"],
          account_id: account.id
        })

      {:ok, app_2} =
        Github.add_app(%{
          installation_id: 456,
          repo_full_names: ["2", "3"],
          account_id: account.id
        })

      assert Github.find_app(account.id, "2").id == app_2.id
    end

    test "get_app_by_installation_id/1" do
      account = user_fixture() |> account_fixture(%{name: "personal"})

      assert Github.get_app_by_installation_id(123) == nil
      {:ok, _} = Github.add_app(%{installation_id: 123, account_id: account.id})
      assert Github.get_app_by_installation_id(123).installation_id == 123
    end

    test "delete_app/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      {:ok, app} = Github.add_app(%{installation_id: 123, account_id: account.id})

      assert Github.list_apps(account) |> length() == 1
      Github.delete_app_by_installation_id(app.installation_id)
      assert Github.list_apps(account) |> length() == 0
    end

    test "update_app/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      {:ok, app} = Github.add_app(%{installation_id: 123, account_id: account.id})
      assert app.repo_full_names == []
      {:ok, app} = Github.update_app(app, %{repo_full_names: ["fastrepl/fastrepl"]})
      assert app.repo_full_names == ["fastrepl/fastrepl"]
    end

    test "list_apps/1" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      {:ok, _} = Github.add_app(%{installation_id: 123, account_id: account.id})
      {:ok, _} = Github.add_app(%{installation_id: 456, account_id: account.id})
      assert Github.list_apps(account) |> length() == 2
    end

    test "list_installed_repos/1" do
      account = user_fixture() |> account_fixture(%{name: "personal"})

      assert Github.list_installed_repos(account) == []

      {:ok, _} =
        Github.add_app(%{
          installation_id: 123,
          repo_full_names: ["1"],
          account_id: account.id
        })

      {:ok, _} =
        Github.add_app(%{
          installation_id: 456,
          repo_full_names: ["2", "3"],
          account_id: account.id
        })

      assert Github.list_installed_repos(account) == ["1", "2", "3"]
    end
  end
end
