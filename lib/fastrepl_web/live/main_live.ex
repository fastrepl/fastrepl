defmodule FastreplWeb.MainLive do
  use FastreplWeb, :live_view

  import FastreplWeb.AuthComponents, only: [sign_in_with_github: 1]
  import FastreplWeb.ThreadComponents, only: [thread: 1]

  def render(assigns) do
    ~H"""
    <div>
      <span>Demo:</span>
      <.link href={~p"/demo/new"}>Go</.link>
      <.sign_in_with_github />
    </div>

    <%= for { id, _pid } <- @threads  do %>
      <div class="w-[600px]">
        <.thread
          id={id}
          description={id}
          repo_full_name="langchain-ai/langchain"
          delete_event_name="kill"
        />
      </div>
    <% end %>
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
