defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  import FastreplWeb.ThreadComponents, only: [tasks: 1]
  import FastreplWeb.GithubComponents, only: [repo: 1, issue: 1]

  alias FastreplWeb.Utils.SharedTask

  def render(assigns) do
    ~H"""
    <.svelte
      name="CodeSnippets"
      socket={@socket}
      ssr={false}
      props={
        %{
          phx_submit: "searchEditor",
          input_name: "text",
          root: if(assigns[:repo], do: @repo.full_name, else: "repo"),
          chunks: if(assigns[:repo], do: @repo.chunks, else: []),
          paths: if(assigns[:repo], do: @repo.paths, else: [])
        }
      }
    />

    <div class="fixed -bottom-2 self-center">
      <div class="flex flex-col gap-6">
        <.svelte name="ActionPanel" socket={@socket} ssr={false} />
        <.svelte
          name="ChatEditor"
          socket={@socket}
          ssr={false}
          props={
            %{
              phx_submit: "chatEditor",
              input_name: "text",
              placeholder: "Instruction here: "
            }
          }
        />
      </div>
    </div>

    <div class="fixed left-10 bottom-10">
      <.tasks tasks={@shared_tasks} />
    </div>

    <%= if assigns[:repo] && assigns[:issue] do %>
      <div class="absolute right-10 top-20 flex flex-col gap-4">
        <.repo
          full_name={@repo.full_name}
          description={@repo.description}
          indexing_total={assigns[:indexing_total]}
          indexing_progress={assigns[:indexing_progress]}
        />
        <.issue repo_full_name={@repo.full_name} title={@issue.title} number={@issue.number} />
      </div>
    <% end %>
    """
  end

  def mount(%{"id" => thread_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:#{thread_id}")
    end

    socket =
      socket
      |> assign(:shared_tasks, [])

    cond do
      socket.assigns[:live_action] != :demo and socket.assigns[:current_user] == nil ->
        {:ok, socket |> redirect(to: "/auth/github")}

      true ->
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

  def handle_info({:sync, state}, socket) do
    {:noreply, socket |> update_socket(state)}
  end

  def handle_info(:demo, socket) do
    if Application.get_env(:fastrepl, :env) == :prod do
      Process.link(socket.assigns.orchestrator_pid)
    end

    {:noreply, socket}
  end

  def handle_event("chatEditor", %{"text" => text}, socket) do
    cond do
      not connected?(socket) ->
        {:noreply, socket |> put_flash(:error, "Cannot connect to the server")}

      text not in ["", nil] ->
        GenServer.cast(
          socket.assigns.orchestrator_pid,
          {:submit, text}
        )

        {:noreply, socket}

      true ->
        {:noreply, socket}
    end
  end

  def handle_event("searchEditor", %{"text" => text}, socket) do
    IO.inspect(text)
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

  defp update_socket(socket, {:indexing, {type, value}}) do
    case type do
      :start ->
        socket |> assign(:indexing_progress, 0) |> assign(:indexing_total, value)

      :progress ->
        socket |> assign(:indexing_progress, socket.assigns.indexing_progress + value)

      :done ->
        socket |> assign(:indexing_progress, value)
    end
  end

  defp update_socket(socket, {k, v}) do
    socket |> assign(k, v)
  end
end
