defmodule Fastrepl.ChatManager do
  use GenServer

  def start_link(%{thread_id: thread_id} = args) do
    GenServer.start_link(__MODULE__, args, name: via_registry(thread_id))
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

  @impl true
  def handle_call(:submit, _from, state) do
    res =
      Fastrepl.AI.chat(%{
        model: "gpt-3.5-turbo",
        stream: false,
        messages: [%{role: "user", content: "Hello"}]
      })

    IO.inspect(res)

    {:reply, :ok, state}
  end

  defp via_registry(id) do
    {:via, Registry, {registry_module(), id}}
  end

  defp registry_module() do
    Application.fetch_env!(:fastrepl, :chat_manager_registry)
  end
end
