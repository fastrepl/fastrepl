defmodule Fastrepl.Repo.Migrations.TextForComment do
  use Ecto.Migration

  def change do
    alter table(:comments) do
      modify :content, :text
    end
  end
end
