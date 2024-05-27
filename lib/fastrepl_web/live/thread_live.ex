defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  import FastreplWeb.SessionComponents, only: [github_issue: 1, github_repo: 1]

  def render(assigns) do
    ~H"""
    <div class="bg-gray-50 rounded-md">
      <%= if assigns[:status] != :start_3 do %>
        <div class="flex flex-col gap-1 items-center">
          <div :if={assigns[:github_issue]}>
            <.github_issue
              name={@github_repo.full_name}
              title={@github_issue.title}
              number={@github_issue.number}
            />
          </div>

          <div :if={assigns[:github_repo]}>
            <.github_repo
              name={@github_repo.full_name}
              sha={@github_repo.default_branch_head}
              description={@github_repo.description}
            />
          </div>
        </div>
      <% else %>
        <.svelte
          name="Session"
          socket={@socket}
          ssr={false}
          props={
            %{
              repoFullName: @github_repo.full_name,
              paths: @paths,
              files: @files,
              diffs: [],
              comments: [],
              messages: []
            }
          }
        />
      <% end %>
    </div>
    """
  end

  def mount(%{"id" => thread_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fastrepl.PubSub, "thread:#{thread_id}")
    end

    case find_existing_manager(thread_id) do
      nil ->
        {:ok, socket |> redirect(to: "/threads")}

      pid ->
        existing_state = GenServer.call(pid, :init_state)

        default_state = %{
          manager_pid: pid,
          thread_id: thread_id,
          paths: [],
          files: []
        }

        state = Map.merge(default_state, existing_state)
        {:ok, socket |> assign(state)}
    end
  end

  def handle_event("comment:add", %{"comment" => _comment}, socket) do
    {:noreply, socket}
  end

  def handle_event("file:add", %{"path" => path}, socket) do
    file = GenServer.call(socket.assigns.manager_pid, {:file, path})
    {:reply, file, socket}
  end

  def handle_info({:sync, state}, socket) do
    {:noreply, socket |> assign(state)}
  end

  defp find_existing_manager(thread_id) do
    registry = Application.fetch_env!(:fastrepl, :thread_manager_registry)

    case Registry.lookup(registry, thread_id) do
      [{pid, _value}] when is_pid(pid) -> pid
      [] -> nil
    end
  end
end
