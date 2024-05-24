defmodule FastreplWeb.ChatsLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-4xl">
      <.svelte name="ChatEditor" socket={@socket} ssr={false} props={%{}} />
    </div>

    <button phx-click="submit">Create</button>
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

  def handle_event("test", _params, socket) do
    {:noreply, socket |> assign(:abc, 321) |> push_patch(to: "/chats")}
  end
end
