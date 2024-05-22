defmodule Fastrepl.UsersFixtures do
  alias Fastrepl.Repo
  alias Identity.User

  def user_fixture() do
    %User{
      id: Ecto.UUID.generate()
    }
    |> Repo.insert!()
  end
end
