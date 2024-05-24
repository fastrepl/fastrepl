defmodule Fastrepl.ThreadManager do
  use GenServer, restart: :transient

  def start_link(
        %{
          account_id: account_id,
          thread_id: thread_id,
          issue_number: issue_number
        } = args
      ) do
    GenServer.start_link(__MODULE__, args, name: via_registry(thread_id, account_id))
  end

  @impl true
  def init(args) do
    state =
      Map.new()
      |> Map.put(:self, self())
      |> Map.put(:thread_id, args.thread_id)

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
