defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  import FastreplWeb.ThreadComponents, only: [render_chunk: 1]
  alias Fastrepl.Orchestrator
  alias Fastrepl.FS

  @demo_repo_full_name "brainlid/langchain"

  def render(assigns) do
    ~H"""
    <div class="flex gap-1 fixed -bottom-2 left-1/2 transform -translate-x-1/2">
      <div class="flex flex-col gap-6">
        <.svelte name="ActionPanel" socket={@socket} ssr={false} />
        <.svelte
          name="ChatEditor"
          socket={@socket}
          ssr={false}
          props={
            %{
              input_name: "instruction",
              placeholder: "Reply here: "
            }
          }
        />
      </div>
      <form phx-submit="submit">
        <button
          type="submit"
          id="submit-button"
          phx-hook="Tooltip"
          phx-tooltip-content="Submit"
          phx-tooltip-placement="right"
          class="w-7 h-7 rounded-xl bg-blue-500 hover:bg-blue-600 bottom-[72px] right-2.5 absolute ml-2"
        >
          <.icon name="hero-arrow-up" class="h-3 w-3 bg-gray-100" />
        </button>
      </form>
    </div>

    <%= if assigns[:chunks] do %>
      <.render_chunks socket={@socket} chunks={@chunks} current_chunk={@current_chunk} />
    <% end %>
    """
  end

  def render_chunks(assigns) do
    ~H"""
    <div class="absolute left-10 max-h-[600px] overflow-y-auto">
      <.svelte
        name="TreeView"
        socket={@socket}
        ssr={false}
        props={%{items: @chunks |> Enum.map(& &1.file_path) |> Enum.uniq() |> FS.build_tree()}}
      />
    </div>
    <.render_chunk chunk={@current_chunk} />
    """
  end

  def mount(%{"id" => thread_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:#{thread_id}")
    end

    cond do
      socket.assigns[:live_action] != :demo and socket.assigns[:current_user] ->
        {:ok, socket |> redirect(to: "/auth/github")}

      true ->
        socket =
          case find_existing_orchestrator(thread_id) do
            pid when is_pid(pid) ->
              socket |> assign(thread_id: thread_id, orchestrator_pid: pid)

            _ ->
              {:ok, pid} =
                Orchestrator.start(%{
                  thread_id: thread_id,
                  repo_full_name: @demo_repo_full_name
                })

              socket |> assign(thread_id: thread_id, orchestrator_pid: pid)
          end

        {:ok, socket}
    end
  end

  def handle_info({:sync, state}, socket) do
    {:noreply, socket |> update_socket(state)}
  end

  def handle_event("submit", params, socket) do
    instruction = params["instruction"]

    cond do
      not connected?(socket) ->
        {:noreply, socket |> put_flash(:error, "Cannot connect to the server")}

      instruction not in ["", nil] ->
        socket = socket |> push_event("tiptap:submit", %{})

        state =
          GenServer.call(
            socket.assigns.orchestrator_pid,
            {:submit, %{instruction: instruction}}
          )

        {:noreply, socket |> update_socket(state)}

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("tree:select", %{"path" => path}, socket) do
    if Path.extname(path) == "" do
      {:noreply, socket}
    else
      chunk =
        socket.assigns.chunks
        |> Enum.find(&(&1.file_path == path))

      if chunk do
        {:noreply, socket |> assign(:current_chunk, chunk)}
      else
        {:noreply, socket}
      end
    end
  end

  def handle_event("action:run", %{"action" => action}, socket) do
    IO.inspect(action)
    {:noreply, socket}
  end

  defp find_existing_orchestrator(thread_id) do
    registry = Application.fetch_env!(:fastrepl, :orchestrator_registry)

    case Registry.lookup(registry, thread_id) do
      [{pid, _value}] -> pid
      [] -> nil
    end
  end

  defp update_socket(socket, state) do
    socket = state |> Enum.reduce(socket, fn {k, v}, acc -> assign(acc, k, v) end)

    cond do
      socket.assigns[:chunks] != nil ->
        socket |> assign(:current_chunk, socket.assigns.chunks |> Enum.at(0))

      true ->
        socket
    end
  end
end
