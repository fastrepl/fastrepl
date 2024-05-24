defmodule Fastrepl.Repo.Migrations.CreateGithubApps do
  use Ecto.Migration

  def change do
    create table(:github_apps) do
      add :installation_id, :integer
      add :repo_full_names, {:array, :string}
      add :account_id, references(:accounts, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:github_apps, [:account_id])
    create unique_index(:github_apps, [:installation_id])
  end
end
