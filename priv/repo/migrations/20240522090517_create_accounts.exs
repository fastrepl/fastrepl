defmodule Fastrepl.Repo.Migrations.CreateAccounts do
  use Ecto.Migration

  def change do
    create table(:accounts) do
      add :name, :string
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      timestamps(type: :utc_datetime)
    end

    create index(:accounts, [:user_id])
    create unique_index(:accounts, [:name])
  end
end
