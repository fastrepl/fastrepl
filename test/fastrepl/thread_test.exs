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

    on_exit(fn ->
      Phoenix.PubSub.unsubscribe(Fastrepl.PubSub, "thread:#{thread_id}")
    end)

    %{thread_id: thread_id}
  end

  test "it works", %{thread_id: thread_id} do
    account = user_fixture() |> account_fixture(%{name: "personal"})

    {:ok, _app} =
      Github.add_app(
        account,
        %{installation_id: "123", repo_full_names: ["fastrepl/fastrepl"]}
      )

    {:ok, _pid} =
      ThreadManager.start_link(%{
        account_id: account.id,
        thread_id: thread_id,
        repo_full_name: "fastrepl/fastrepl",
        issue_content: "TODO"
      })

    assert_gh_called(GitHub.Repos.get("fastrepl", "fastrepl"))
  end
end
