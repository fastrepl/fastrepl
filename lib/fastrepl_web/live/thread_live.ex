defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Repository

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
          repoSha: assigns |> get_in([Access.key(:repo), Access.key(:sha)]),
          issueTitle: assigns |> get_in([Access.key(:github_issue), Access.key(:title)]),
          issueNumber: assigns |> get_in([Access.key(:github_issue), Access.key(:number)]),
          indexingTotal: assigns |> get_in([Access.key(:indexing), Access.key(:total)]),
          indexingProgress: assigns |> get_in([Access.key(:indexing), Access.key(:progress)]),
          files: assigns |> get_in([Access.key(:repo), Access.key(:original_files)]),
          paths: assigns |> get_in([Access.key(:repo), Access.key(:paths)]),
          wipPaths: assigns |> get_in([Access.key(:wip_paths, [])]),
          comments: assigns |> get_in([Access.key(:repo), Access.key(:comments)]),
          messages: @messages,
          diffs:
            assigns
            |> get_in([Access.key(:repo, %{}), Access.key(:diffs, [])])
            |> Enum.map(fn diff ->
              %{path: Repository.Diff.display_path(diff), content: Repository.Diff.to_patch(diff)}
            end),
          steps: @steps,
          currentStep: @current_step,
          threadId: @thread_id,
          searching: assigns |> get_in([Access.key(:searching, false)])
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
      |> assign(:thread_id, thread_id)
      |> assign(:steps, ["Initialization", "Planning", "Execution"])
      |> assign(:current_step, nil)
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

          {:ok, socket |> assign(orchestrator_pid: pid)}

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
    comments =
      comments
      |> Enum.map(&Map.new(&1, fn {k, v} -> {String.to_atom(k), v} end))
      |> Enum.map(&struct(Fastrepl.Repository.Comment, &1))

    socket =
      socket
      |> assign(:repo, %{socket.assigns.repo | comments: comments})
      |> sync_with_orchestrator(:repo)
      |> sync_with_views(:repo)

    {:noreply, socket}
  end

  def handle_event("file:add", %{"path" => path}, socket) do
    file = Repository.File.from!(socket.assigns.repo, path)
    repo = socket.assigns.repo |> Repository.add_file!(file)

    socket =
      socket
      |> assign(:repo, repo)
      |> sync_with_orchestrator(:repo)
      |> sync_with_views(:repo)

    {:noreply, socket}
  end

  def handle_event("chat:submit", %{"message" => message, "references" => references}, socket) do
    messages = socket.assigns.messages ++ [message, %{role: "assistant", content: ""}]

    GenServer.cast(
      socket.assigns.orchestrator_pid,
      {:chat, %{messages: messages, references: references}}
    )

    {:noreply, socket |> assign(:messages, messages)}
  end

  def handle_event("execute", _params, socket) do
    GenServer.cast(socket.assigns.orchestrator_pid, :execute)
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
