defmodule Fastrepl.ThreadManager do
  use GenServer, restart: :transient

  alias Fastrepl.Github

  def start_link(%{account_id: account_id, thread_id: thread_id} = args) do
    GenServer.start_link(__MODULE__, args, name: via_registry(thread_id, account_id))
  end

  @impl true
  def init(%{thread_id: thread_id, repo_full_name: repo_full_name, issue_number: issue_number}) do
    repo = Github.Repo.from!(repo_full_name)
    issue = Github.Issue.from!(repo_full_name, issue_number)

    state =
      Map.new()
      |> Map.put(:self, self())
      |> Map.put(:thread_id, thread_id)
      |> Map.put(:github_repo, repo)
      |> Map.put(:github_issue, issue)

    {:ok, state}
  end

  @impl true
  def init(%{thread_id: thread_id}) do
    state =
      Map.new()
      |> Map.put(:self, self())
      |> Map.put(:thread_id, thread_id)

    {:ok, state}
  end

  @impl true
  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  defp via_registry(thread_id, account_id) do
    {:via, Registry, {registry_module(), thread_id, %{account_id: account_id}}}
  end

  defp registry_module() do
    Application.fetch_env!(:fastrepl, :thread_manager_registry)
  end
end
