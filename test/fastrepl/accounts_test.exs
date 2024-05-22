defmodule Fastrepl.AccountsTest do
  use Fastrepl.DataCase

  import Fastrepl.UsersFixtures

  alias Fastrepl.Accounts
  alias Fastrepl.Accounts.Account

  describe "accounts" do
    test "create_account/2" do
      user = user_fixture()
      {:ok, account} = Accounts.create_account(user, %{name: "personal"})
      assert account.name == "personal"

      {:error, changeset} = Accounts.create_account(user, %{name: "personal"})
      assert changeset.errors |> length() == 1
    end

    test "list_accounts/1" do
      user = user_fixture()
      {:ok, _} = Accounts.create_account(user, %{name: "personal"})
      {:ok, _} = Accounts.create_account(user, %{name: "team"})
      assert Accounts.list_accounts(user) |> length() == 2
    end

    test "add_member/2" do
      user_1 = user_fixture()
      user_2 = user_fixture()
      {:ok, account} = Accounts.create_account(user_1, %{name: "personal"})
      {:ok, member} = Accounts.add_member(account, user_2)
      assert member.user_id == user_2.id
      assert member.account_id == account.id
    end

    test "list_members/1" do
      user_1 = user_fixture()
      user_2 = user_fixture()

      {:ok, account} = Accounts.create_account(user_1, %{name: "personal"})

      assert Accounts.list_members(account) |> length() == 1
      {:ok, member} = Accounts.add_member(account, user_2)
      assert Accounts.list_members(account) |> length() == 2
    end
  end
end
