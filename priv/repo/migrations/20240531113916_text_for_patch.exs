defmodule Fastrepl.Repo.Migrations.TextForPatch do
  use Ecto.Migration

  def change do
    alter table(:patches) do
      modify :content, :text
    end
  end
end
