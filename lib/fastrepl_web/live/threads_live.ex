defmodule FastreplWeb.ThreadsLive do
  use FastreplWeb, :live_view

  import FastreplWeb.ThreadComponents, only: [thread: 1]

  def render(assigns) do
    ~H"""
    <h2 id="threads" class="text-lg font-semibold">
      Fastrepl
    </h2>

    <p class="mt-2">
      You can try out the demo <.link href={~p"/demo"} class="underline text-blue-500 font-semibold">here</.link>.
    </p>

    <div class="flex flex-col gap-2 mt-4">
      <%= for { id, _pid } <- @threads  do %>
        <div class="w-[600px]">
          <.thread id={id} description={id} repo_full_name={id} delete_event_name="kill" />
        </div>
      <% end %>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    threads =
      Registry.select(Application.fetch_env!(:fastrepl, :orchestrator_registry), [
        {{:"$1", :"$2", :_}, [], [{{:"$1", :"$2"}}]}
      ])

    socket =
      socket |> assign(:threads, threads)

    {:ok, socket}
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
