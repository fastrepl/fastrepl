defmodule Fastrepl.Accounts do
  import Ecto.Query, warn: false
  alias Fastrepl.Repo

  alias Identity.User
  alias Fastrepl.Accounts.Member
  alias Fastrepl.Accounts.Account

  def list_accounts(%User{} = user) do
    Repo.all(from a in Account, where: a.user_id == ^user.id)
  end

  def get_account_by_id(id) do
    Repo.one(from a in Account, where: a.id == ^id)
  end

  def get_account_by_name(%User{} = user, name) do
    Repo.one(from a in Account, where: a.user_id == ^user.id and a.name == ^name)
  end

  def create_account(%User{} = user, attrs \\ %{}) do
    transaction =
      Ecto.Multi.new()
      |> Ecto.Multi.insert(:account, fn _ ->
        %Account{}
        |> Account.changeset(attrs)
        |> Ecto.Changeset.put_assoc(:user, user)
      end)
      |> Ecto.Multi.insert(:member, fn %{account: account} ->
        %Member{}
        |> Member.changeset(%{})
        |> Ecto.Changeset.put_assoc(:user, user)
        |> Ecto.Changeset.put_assoc(:account, account)
      end)
      |> Repo.transaction()

    case transaction do
      {:ok, %{account: account}} -> {:ok, account}
      {:error, _, changeset, _} -> {:error, changeset}
    end
  end

  def create_account!(%User{} = user, attrs \\ %{}) do
    {:ok, account} = create_account(user, attrs)
    account
  end

  def add_member(%Account{} = account, %User{} = user) do
    %Member{}
    |> Member.changeset(%{})
    |> Ecto.Changeset.put_assoc(:user, user)
    |> Ecto.Changeset.put_assoc(:account, account)
    |> Repo.insert()
  end

  def list_members(%Account{} = account) do
    Repo.all(from m in Member, where: m.account_id == ^account.id)
  end
end
