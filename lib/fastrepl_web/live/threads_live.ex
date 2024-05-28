defmodule FastreplWeb.ThreadsLive do
  use FastreplWeb, :live_view

  import FastreplWeb.ThreadComponents, only: [thread_list_item: 1]

  def render(assigns) do
    ~H"""
    <div class="px-[15px] py-[20px]">
      <h2 class="text-xl font-semibold">Threads</h2>

      <ul class="flex flex-col gap-1 mt-8 max-w-[400px]">
        <%= for {id, _pid} <- @threads do %>
          <li>
            <.thread_list_item id={id} />
          </li>
        <% end %>
      </ul>
    </div>
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
