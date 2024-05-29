defmodule Fastrepl.Repo.Migrations.CreatePatches do
  use Ecto.Migration

  def change do
    create table(:patches) do
      add :session_id, references(:sessions, on_delete: :delete_all)
      add :status, :string
      add :path, :string
      add :content, :string

      timestamps(type: :utc_datetime)
    end

    create index(:patches, [:session_id])
  end
end
