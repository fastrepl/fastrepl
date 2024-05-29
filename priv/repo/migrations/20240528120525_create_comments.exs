defmodule Fastrepl.Repo.Migrations.CreateComments do
  use Ecto.Migration

  def change do
    create table(:comments) do
      add :session_id, references(:sessions, on_delete: :delete_all)
      add :file_path, :string
      add :line_start, :integer
      add :line_end, :integer
      add :content, :string

      timestamps(type: :utc_datetime)
    end

    create index(:comments, [:session_id])
  end
end
