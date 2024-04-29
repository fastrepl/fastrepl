defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Retrieval.Chunker

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

    <div class="absolute left-10 bottom-10">
      <.svelte name="TaskPanel" socket={@socket} ssr={false} />
    </div>

    <%= if assigns[:chunks] do %>
      <.svelte name="CodeSnippets" socket={@socket} ssr={false} props={%{chunks: @chunks}} />
    <% end %>
    """
  end

  def mount(%{"id" => thread_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:#{thread_id}")
    end

    cond do
      socket.assigns[:live_action] != :demo and socket.assigns[:current_user] == nil ->
        {:ok, socket |> redirect(to: "/auth/github")}

      true ->
        case find_existing_orchestrator(thread_id) do
          pid when is_pid(pid) ->
            if socket.assigns[:live_action] == :demo do
              send(self(), :demo)
            end

            {:ok, socket |> assign(thread_id: thread_id, orchestrator_pid: pid)}

          nil ->
            dest = if socket.assigns[:live_action] == :demo, do: "/demo", else: "/"
            {:ok, socket |> redirect(to: dest)}
        end
    end
  end

  def handle_info({:sync, state}, socket) do
    {:noreply, socket |> update_socket(state)}
  end

  def handle_info(:demo, socket) do
    Process.link(socket.assigns.orchestrator_pid)
    {:noreply, socket}
  end

  def handle_event("submit", params, socket) do
    instruction = params["instruction"]

    cond do
      not connected?(socket) ->
        {:noreply, socket |> put_flash(:error, "Cannot connect to the server")}

      instruction not in ["", nil] ->
        socket =
          socket
          |> push_event("tiptap:submit", %{})
          |> push_event("task:upsert", %{"task" => %{"name" => instruction}})

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
    socket =
      state
      |> Enum.reduce(socket, fn {k, v}, acc ->
        if k == :chunks do
          acc
          |> assign(:chunks, Chunker.dedupe((socket.assigns[:chunks] || []) ++ v))
          |> assign(:current_chunk, v |> Enum.at(0))
        else
          assign(acc, k, v)
        end
      end)

    cond do
      socket.assigns[:chunks] != nil and socket.assigns[:current_chunk] == nil ->
        socket |> assign(:current_chunk, socket.assigns.chunks |> Enum.at(0))

      true ->
        socket
    end
  end
end
