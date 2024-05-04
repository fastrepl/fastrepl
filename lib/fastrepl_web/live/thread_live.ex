defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  import FastreplWeb.ThreadComponents, only: [horizontal_progress_bar: 1]
  import FastreplWeb.GithubComponents, only: [repo: 1, issue: 1]

  alias FastreplWeb.Utils.SharedTask

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 items-center">
      <div class="w-[600px]">
        <.horizontal_progress_bar
          current_step={@current_step}
          steps={["Initialization", "Planning", "Execution"]}
        />
      </div>

      <%= case @current_step do %>
        <% "Initialization" -> %>
          <%= if assigns[:repo] && assigns[:issue] do %>
            <div class="flex flex-col gap-4 mt-10">
              <.repo
                full_name={@repo.full_name}
                description={@repo.description}
                indexing_total={@repo.indexing_total}
                indexing_progress={@repo.indexing_progress}
              />
              <.issue repo_full_name={@repo.full_name} title={@issue.title} number={@issue.number} />

              <.button
                phx-click="move_step"
                phx-value-name="Planning"
                class="w-full text-lg mt-4"
                disabled={!@repo.indexing_total || @repo.indexing_total != @repo.indexing_progress}
              >
                Next
              </.button>
            </div>
          <% end %>
        <% "Planning" -> %>
          <div class="w-full">
            <.svelte
              name="Planner"
              socket={@socket}
              ssr={false}
              props={
                %{
                  chunks: if(assigns[:repo], do: @repo.chunks, else: [])
                }
              }
            />
          </div>
        <% "Execution" -> %>
          <div>Execution</div>
      <% end %>
    </div>
    """
  end

  def mount(%{"id" => thread_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:#{thread_id}")
    end

    socket =
      socket
      |> assign(:current_step, "Initialization")
      |> assign(:shared_tasks, [])

    if socket.assigns[:live_action] != :demo and socket.assigns[:current_user] == nil do
      {:ok, socket |> redirect(to: "/auth/github")}
    else
      case find_existing_orchestrator(thread_id) do
        pid when is_pid(pid) ->
          if socket.assigns[:live_action] == :demo do
            send(self(), :demo)
          end

          state = GenServer.call(pid, :state)
          send(self(), {:sync, state})

          {:ok, socket |> assign(thread_id: thread_id, orchestrator_pid: pid)}

        nil ->
          dest = if socket.assigns[:live_action] == :demo, do: "/demo", else: "/"
          {:ok, socket |> redirect(to: dest)}
      end
    end
  end

  def handle_event("move_step", %{"name" => name}, socket) do
    GenServer.cast(socket.assigns.orchestrator_pid, {:sync, %{current_step: name}})
    {:noreply, socket |> assign(:current_step, name)}
  end

  def handle_event("comment", data, socket) do
    %{"file_path" => file_path, "line_start" => line_start, "line_end" => line_end} = data

    IO.inspect(file_path, label: "file_path")
    IO.inspect(line_start, label: "line_start")
    IO.inspect(line_end, label: "line_end")

    {:noreply, socket}
  end

  def handle_info({:sync, state}, socket) do
    {:noreply, socket |> update_socket(state)}
  end

  def handle_info(:demo, socket) do
    if Application.get_env(:fastrepl, :env) == :prod do
      Process.link(socket.assigns.orchestrator_pid)
    end

    {:noreply, socket}
  end

  defp find_existing_orchestrator(thread_id) do
    registry = Application.fetch_env!(:fastrepl, :orchestrator_registry)

    case Registry.lookup(registry, thread_id) do
      [{pid, _value}] -> pid
      [] -> nil
    end
  end

  defp update_socket(socket, state) when is_map(state) do
    state
    |> Enum.reduce(socket, fn {k, v}, acc -> update_socket(acc, {k, v}) end)
  end

  defp update_socket(socket, {:view, state}) do
    state
    |> Enum.reduce(socket, fn {k, v}, acc -> assign(acc, k, v) end)
  end

  defp update_socket(socket, {:issue, issue}) do
    socket |> assign(:issue, issue)
  end

  defp update_socket(socket, {:repo, repo}) do
    socket |> assign(:repo, repo)
  end

  defp update_socket(socket, {:task, {id, name}}) do
    Enum.find_index(socket.assigns.shared_tasks, fn task -> task.id == id end)
    |> case do
      nil ->
        socket
        |> assign(
          :shared_tasks,
          [SharedTask.loading(id, name) | socket.assigns.shared_tasks]
        )

      index ->
        socket
        |> assign(
          :shared_tasks,
          List.update_at(socket.assigns.shared_tasks, index, &SharedTask.ok(&1, name))
        )
    end
  end

  defp update_socket(socket, {k, v}) do
    socket |> assign(k, v)
  end
end
