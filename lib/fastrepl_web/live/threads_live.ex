defmodule FastreplWeb.ThreadsLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div></div>
    <h2 class="font-semibold text-xl">
      Threads
    </h2>

    <button
      phx-click="new_thread"
      class="mt-4 px-2 py-1 rounded-md bg-blue-50 text-blue-700 hover:bg-blue-100"
    >
      New thread
    </button>

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

  def handle_event("new_thread", _params, socket) do
    thread_id = Nanoid.generate()

    {:ok, _} =
      DynamicSupervisor.start_child(
        Fastrepl.ThreadManagerSupervisor,
        {Fastrepl.ThreadManager,
         %{thread_id: thread_id, account_id: socket.assigns.current_account.id}}
      )

    socket =
      socket
      |> assign(:thread_id, thread_id)
      |> push_navigate(to: "/thread/#{thread_id}")

    {:noreply, socket}
  end

  defp list_active_threads(account_id) do
    Registry.select(Application.fetch_env!(:fastrepl, :thread_manager_registry), [
      {{:"$1", :"$2", %{account_id: account_id}}, [], [{{:"$1", :"$2"}}]}
    ])
  end
end
