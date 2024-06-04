defmodule Fastrepl.Repo.Migrations.NoUniqueAccount do
  use Ecto.Migration

  def change do
    drop unique_index(:accounts, [:name])
    create unique_index(:accounts, [:user_id, :name])
  end
end
