defmodule Fastrepl.AccountsFixtures do
  alias Fastrepl.Accounts
  alias Identity.User

  def account_fixture(%User{} = user, attrs \\ %{}) do
    Accounts.create_account!(user, attrs)
  end
end
