defmodule Fastrepl.Repo.Migrations.CreateBillings do
  use Ecto.Migration

  def change do
    create table(:billings) do
      add :account_id, references(:accounts, on_delete: :nothing)
      add :stripe_customer, :map
      add :stripe_subscription, :map

      timestamps(type: :utc_datetime)
    end

    create index(:billings, [:account_id])
  end
end
