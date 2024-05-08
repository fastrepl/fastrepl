defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Repository
  alias FastreplWeb.Utils.SharedTask

  def render(assigns) do
    ~H"""
    <.svelte
      name="Thread"
      socket={@socket}
      ssr={false}
      props={
        %{
          repoFullName: assigns |> get_in([Access.key(:repo), Access.key(:full_name)]),
          repoDescription: assigns |> get_in([Access.key(:repo), Access.key(:description)]),
          issueTitle: assigns |> get_in([Access.key(:issue), Access.key(:title)]),
          issueNumber: assigns |> get_in([Access.key(:issue), Access.key(:number)]),
          indexingTotal: assigns |> get_in([Access.key(:repo), Access.key(:indexing_total)]),
          indexingProgress: assigns |> get_in([Access.key(:repo), Access.key(:indexing_progress)]),
          files: assigns |> get_in([Access.key(:repo), Access.key(:files)]),
          paths: assigns |> get_in([Access.key(:repo), Access.key(:paths)]),
          comments: assigns |> get_in([Access.key(:repo), Access.key(:comments)]),
          messages: @messages,
          diffs: assigns |> get_in([Access.key(:repo), Access.key(:diffs)]),
          steps: @steps,
          currentStep: @current_step,
          threadId: @thread_id
        }
      }
    />
    """
  end

  def mount(%{"id" => thread_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:#{thread_id}")
    end

    socket =
      socket
      |> assign(:steps, ["Initialization", "Planning", "Execution"])
      |> assign(:current_step, nil)
      |> assign(:shared_tasks, [])
      |> assign(:messages, [])

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

          socket =
            socket
            |> assign(thread_id: thread_id, orchestrator_pid: pid)

          {:ok, socket}

        nil ->
          dest = if socket.assigns[:live_action] == :demo, do: "/demo", else: "/"
          {:ok, socket |> redirect(to: dest)}
      end
    end
  end

  def handle_event("step:set", %{"step" => step}, socket) do
    socket =
      socket
      |> assign(:current_step, step)
      |> sync_with_orchestrator(:current_step)

    {:noreply, socket}
  end

  def handle_event("comment:set", %{"comments" => comments}, socket) do
    socket =
      socket
      |> assign(:repo, %{socket.assigns.repo | comments: comments})
      |> sync_with_orchestrator(:repo)
      |> sync_with_views(:repo)

    {:noreply, socket}
  end

  def handle_event("file:add", %{"path" => path}, socket) do
    file = Repository.File.from!(socket.assigns.repo.root_path, path)
    files = [file | socket.assigns.repo.files]

    socket =
      socket
      |> assign(:repo, %{socket.assigns.repo | files: files})
      |> sync_with_orchestrator(:repo)
      |> sync_with_views(:repo)

    {:noreply, socket}
  end

  def handle_event("chat:submit", %{"message" => message}, socket) do
    messages = socket.assigns.messages ++ [message, %{role: "assistant", content: ""}]
    GenServer.cast(socket.assigns.orchestrator_pid, {:chat, %{messages: messages}})

    {:noreply, socket |> assign(:messages, messages)}
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

  defp sync_with_orchestrator(socket, key) when is_atom(key) do
    GenServer.cast(socket.assigns.orchestrator_pid, {:sync, %{key => socket.assigns[key]}})
    socket
  end

  defp sync_with_views(socket, key) when is_atom(key) do
    Phoenix.PubSub.broadcast(
      Fastrepl.PubSub,
      "thread:#{socket.assigns.thread_id}",
      {:sync, %{key => socket.assigns[key]}}
    )

    socket
  end
end
