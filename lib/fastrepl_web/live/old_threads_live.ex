defmodule FastreplWeb.OldThreadsLive do
  use FastreplWeb, :live_view

  import FastreplWeb.ThreadComponents, only: [thread: 1]

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <h2 class="text-lg font-semibold">
        Fastrepl
      </h2>

      <div class="flex flex-col gap-2 mt-4">
        <%= for { id, _pid } <- @threads  do %>
          <div class="w-[600px]">
            <.thread id={id} description={id} repo_full_name={id} delete_event_name="kill" />
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    threads =
      Registry.select(Application.fetch_env!(:fastrepl, :orchestrator_registry), [
        {{:"$1", :"$2", %{type: :live}}, [], [{{:"$1", :"$2"}}]}
      ])

    {:ok, socket |> assign(:threads, threads)}
  end

  def handle_event("kill", %{"id" => target}, socket) do
    index =
      socket.assigns.threads |> Enum.find_index(fn {id, _pid} -> id == target end)

    if index != nil do
      pid = socket.assigns.threads |> Enum.at(index) |> elem(1)
      Process.exit(pid, :normal)
    end

    threads = socket.assigns.threads |> List.delete_at(index)
    socket = socket |> assign(:threads, threads)
    {:noreply, socket}
  end
end
