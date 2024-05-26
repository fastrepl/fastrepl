defmodule FastreplWeb.ChatsLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="px-[15px] py-[20px]">
      <h2 class="text-xl font-semibold">Chats</h2>
      <p>Chat mode is planned, but not yet available.</p>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def handle_event("submit", _params, socket) do
    chat_id = Nanoid.generate()

    {:ok, _} =
      DynamicSupervisor.start_child(
        Fastrepl.ChatManagerSupervisor,
        {Fastrepl.ChatManager, %{chat_id: chat_id}}
      )

    socket =
      socket
      |> assign(:chat_id, chat_id)
      |> push_navigate(to: "/chat/#{chat_id}")

    {:noreply, socket}
  end
end
