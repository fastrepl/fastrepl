defmodule Fastrepl.Repo.Migrations.CreateMembers do
  use Ecto.Migration

  def change do
    create table(:members) do
      add :user_id, references(:users, type: :binary_id, on_delete: :delete_all)
      add :account_id, references(:accounts, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:members, [:user_id])
    create index(:members, [:account_id])
  end
end
