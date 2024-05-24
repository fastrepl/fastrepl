defmodule Fastrepl.ThreadTest do
  use Fastrepl.DataCase
  use ExUnit.Case, async: false
  use GitHub.Testing, shared: true

  import Fastrepl.UsersFixtures
  import Fastrepl.AccountsFixtures

  alias Fastrepl.Github
  alias Fastrepl.ThreadManager

  setup do
    thread_id = Nanoid.generate()
    Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:#{thread_id}")

    %{thread_id: thread_id}
  end

  test "it works", %{thread_id: thread_id} do
    account = user_fixture() |> account_fixture(%{name: "personal"})

    {:ok, app} =
      Github.add_app(
        account,
        %{installation_id: "123", repo_full_names: ["fastrepl/fastrepl"]}
      )

    {:ok, _pid} =
      ThreadManager.start_link(%{
        account_id: account.id,
        thread_id: thread_id,
        repo_full_name: "fastrepl/fastrepl",
        issue_number: 1,
        installation_id: app.installation_id
      })

    assert_gh_called(GitHub.Repos.get("fastrepl", "fastrepl"))
  end
end
