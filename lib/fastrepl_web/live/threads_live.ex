defmodule FastreplWeb.ThreadsLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div></div>
    <h2 class="font-semibold text-xl">
      Threads
    </h2>

    <ul>
      <%= for {id, _pid} <- @threads do %>
        <li>
          <.link navigate={~p"/thread/#{id}"} class="text-sm font-semibold hover:underline">
            <%= id %>
          </.link>
        </li>
      <% end %>
    </ul>
    """
  end

  def mount(_params, _session, socket) do
    threads = [] ++ list_active_threads(socket.assigns.current_account.id)

    socket = socket |> assign(:threads, threads)
    {:ok, socket}
  end

  defp list_active_threads(account_id) do
    Registry.select(Application.fetch_env!(:fastrepl, :thread_manager_registry), [
      {{:"$1", :"$2", %{account_id: account_id}}, [], [{{:"$1", :"$2"}}]}
    ])
  end
end
