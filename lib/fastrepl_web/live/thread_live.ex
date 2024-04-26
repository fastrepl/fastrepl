defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Orchestrator

  @demo_repo_full_name "langchain-ai/langchain"

  def render(assigns) do
    ~H"""
    <div>Thread</div>
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
    """
  end

  def mount(%{"id" => thread_id}, _session, socket) do
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
