defmodule FastreplWeb.ThreadDebugLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div
      id="debug-log"
      phx-hook="Autoscroll"
      class={[
        "flex flex-col",
        "h-[calc(100vh-100px)] overflow-y-hidden hover:overflow-y-auto",
        "rounded-sm text-sm"
      ]}
    >
      <%= for event <- Enum.reverse(@events) do %>
        <div
          phx-mounted={
            JS.transition({"ease-out duration-1000", "opacity-20", "opacity-100"}, time: 1000)
          }
          class={[
            "px-1 py-0.5 border border-gray-200",
            "bg-gray-100 hover:bg-gray-200"
          ]}
        >
          <span><%= event.timestamp |> DateTime.to_iso8601() |> String.slice(0..-9) %></span>
          <span><%= event.text %></span>
        </div>
      <% end %>
    </div>
    """
  end

  def mount(%{"id" => thread_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:debug:#{thread_id}")
    end

    {:ok, socket |> assign(events: [])}
  end

  def handle_info({:log, data}, socket) do
    events = [%{timestamp: DateTime.utc_now(), text: to_string(data)} | socket.assigns.events]
    {:noreply, socket |> assign(events: events)}
  end
end
