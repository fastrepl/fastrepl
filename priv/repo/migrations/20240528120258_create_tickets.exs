defmodule Fastrepl.Repo.Migrations.CreateTickets do
  use Ecto.Migration

  def change do
    create table(:tickets) do
      add :session_id, references(:sessions, on_delete: :delete_all)
      add :base_commit_sha, :string
      add :github_repo_full_name, :string
      add :github_issue_number, :integer
      add :fastrepl_issue_content, :string

      timestamps(type: :utc_datetime)
    end

    create index(:tickets, [:session_id])
  end
end
