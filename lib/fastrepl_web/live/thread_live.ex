defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  import FastreplWeb.ThreadComponents, only: [snippet: 1]
  alias Fastrepl.Orchestrator

  @demo_repo_full_name "brainlid/langchain"

  def render(assigns) do
    ~H"""
    <div class="flex gap-1 fixed -bottom-2 left-1/2 transform -translate-x-1/2">
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
      <form phx-submit="submit">
        <button
          type="submit"
          id="submit-button"
          phx-hook="Tooltip"
          phx-tooltip-content="Submit"
          phx-tooltip-placement="right"
          class="w-7 h-7 rounded-xl bg-blue-500 hover:bg-blue-600 top-2 right-2.5 absolute ml-2"
        >
          <.icon name="hero-arrow-up" class="h-3 w-3 bg-gray-100" />
        </button>
      </form>
    </div>

    <%= if assigns[:code] do %>
      <.snippet code={@code} highlight_lines={[[1, 1]]} />
    <% end %>
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

  defp find_existing_orchestrator(thread_id) do
    registry = Application.fetch_env!(:fastrepl, :orchestrator_registry)

    case Registry.lookup(registry, thread_id) do
      [{pid, _value}] -> pid
      [] -> nil
    end
  end

  defp update_socket(socket, state) do
    state |> Enum.reduce(socket, fn {k, v}, acc -> assign(acc, k, v) end)
  end
end
