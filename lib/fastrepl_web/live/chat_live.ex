defmodule FastreplWeb.ChatLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div>chat</div>
    <button phx-click="submit">Submit</button>
    """
  end

  def mount(%{"id" => chat_id}, _session, socket) do
    case find_existing_orchestrator(chat_id) do
      pid when is_pid(pid) ->
        state = GenServer.call(pid, :state)
        send(self(), {:sync, state})

        socket =
          socket
          |> assign(:chat_id, chat_id)
          |> assign(:manager_pid, pid)

        {:ok, socket}

      nil ->
        {:ok, socket |> redirect(to: "/chats")}
    end
  end

  def handle_event("submit", _params, socket) do
    GenServer.call(socket.assigns.manager_pid, :submit)
    {:noreply, socket}
  end

  defp find_existing_orchestrator(chat_id) do
    registry = Application.fetch_env!(:fastrepl, :chat_manager_registry)

    case Registry.lookup(registry, chat_id) do
      [{pid, _value}] -> pid
      [] -> nil
    end
  end
end
