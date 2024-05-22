defmodule Fastrepl.Accounts.Member do
  use Ecto.Schema
  import Ecto.Changeset

  alias Identity.User
  alias Fastrepl.Accounts.Account

  schema "members" do
    belongs_to :user, User, type: :binary_id
    belongs_to :account, Account

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(member, attrs) do
    member
    |> cast(attrs, [])
    |> assoc_constraint(:user)
    |> assoc_constraint(:account)
  end
end
