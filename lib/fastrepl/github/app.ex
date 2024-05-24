defmodule Fastrepl.Github.App do
  use Ecto.Schema
  import Ecto.Changeset

  alias Fastrepl.Accounts.Account

  schema "github_apps" do
    field :installation_id, :integer
    field :repo_full_names, {:array, :string}, default: []
    belongs_to :account, Account

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(app, attrs) do
    app
    |> cast(attrs, [:installation_id, :repo_full_names])
    |> validate_required([:installation_id])
  end
end
