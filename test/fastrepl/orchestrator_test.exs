defmodule Fastrepl.OrchestratorTest do
  use ExUnit.Case, async: true

  import Mox, only: [verify_on_exit!: 1]
  setup :verify_on_exit!

  alias Fastrepl.Orchestrator

  setup do
    Application.put_env(:fastrepl, :clone_dir, System.tmp_dir!())
    thread_id = Nanoid.generate()

    {:ok, pid} =
      Orchestrator.start(%{
        thread_id: thread_id,
        repo_full_name: "fastrepl/fastrepl",
        issue_number: 1
      })

    Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:#{thread_id}")
    on_exit(fn -> Process.exit(pid, :normal) end)

    %{pid: pid, thread_id: thread_id}
  end

  test "it works", %{pid: pid} do
    assert Process.alive?(pid)
  end
end
