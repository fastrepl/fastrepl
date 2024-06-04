defmodule Fastrepl.Accounts.Account do
  use Ecto.Schema
  import Ecto.Changeset

  alias Identity.User
  alias Fastrepl.Accounts.Member

  @type t :: %__MODULE__{}

  schema "accounts" do
    field :name, :string
    belongs_to :user, User, type: :binary_id
    many_to_many :users, User, join_through: Member

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:user_id, :name])
  end
end
