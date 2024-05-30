defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  import FastreplWeb.SessionComponents, only: [github_issue: 1, github_repo: 1]

  def render(assigns) do
    ~H"""
    <div class="bg-gray-50 rounded-md">
      <%= if assigns[:status] == :init do %>
        <div class="flex flex-row gap-2 items-center justify-center h-[calc(100vh-90px)]">
          <span>We are now working on</span>
          <div :if={assigns[:github_issue]}>
            <.github_issue
              name={@github_repo.full_name}
              title={@github_issue.title}
              number={@github_issue.number}
            />
          </div>
          <span>in</span>
          <div :if={assigns[:github_repo]}>
            <.github_repo
              name={@github_repo.full_name}
              sha={@github_repo.default_branch_head}
              description={@github_repo.description}
            />
          </div>
          <span>...</span>
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
              comments: @comments,
              diffs: @patches,
              executing: @status == :run
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

    case find_or_start_manager(%{
           account_id: socket.assigns.current_account.id,
           thread_id: thread_id
         }) do
      nil ->
        socket =
          socket
          |> put_flash(:error, "Failed to start session.")
          |> redirect(to: "/threads")

        {:ok, socket}

      pid ->
        existing_state = GenServer.call(pid, :init_state)

        default_state = %{
          manager_pid: pid,
          thread_id: thread_id,
          paths: [],
          files: [],
          comments: [],
          patches: []
        }

        state = Map.merge(default_state, existing_state)
        {:ok, socket |> assign(state)}
    end
  end

  def handle_event("comment:add", %{"comment" => comment}, socket) do
    :ok = GenServer.call(socket.assigns.manager_pid, {:comment_add, comment})
    {:noreply, socket}
  end

  def handle_event("file:add", %{"path" => path}, socket) do
    file = GenServer.call(socket.assigns.manager_pid, {:file_add, path})
    {:reply, %{file: file}, socket}
  end

  def handle_event("execute", %{}, socket) do
    :ok = GenServer.call(socket.assigns.manager_pid, :execute)
    {:noreply, socket}
  end

  def handle_event("patch:download", %{}, socket) do
    id = Nanoid.generate()
    patch = socket.assigns.patches |> Enum.map(& &1.content) |> Enum.join("\n")

    :ok = Fastrepl.Temp.set(id, patch)
    url = FastreplWeb.Endpoint.url() <> "/patch/view/#{id}"

    {:reply, %{url: url}, socket}
  end

  def handle_event("comments:create", %{"comments" => comments}, socket) do
    :ok = GenServer.call(socket.assigns.manager_pid, {:comments_create, comments})
    {:noreply, socket}
  end

  def handle_event("comments:delete", %{"comments" => comments}, socket) do
    :ok = GenServer.call(socket.assigns.manager_pid, {:comments_delete, comments})
    {:noreply, socket}
  end

  def handle_event("comments:update", %{"comments" => comments}, socket) do
    :ok = GenServer.call(socket.assigns.manager_pid, {:comments_update, comments})
    {:noreply, socket}
  end

  def handle_event("pr:create", %{}, socket) do
    reply =
      case GenServer.call(socket.assigns.manager_pid, :pr_create, 12 * 1000) do
        {:ok, url} -> %{url: url}
        _ -> %{url: ""}
      end

    {:reply, reply, socket}
  end

  def handle_info({:sync, state}, socket) do
    {:noreply, socket |> assign(state)}
  end

  defp find_or_start_manager(%{account_id: _, thread_id: thread_id} = args) do
    find_existing_manager(thread_id) || start_new_manager(args)
  end

  defp find_existing_manager(thread_id) do
    registry = Application.fetch_env!(:fastrepl, :thread_manager_registry)

    case Registry.lookup(registry, thread_id) do
      [{pid, _value}] when is_pid(pid) -> pid
      [] -> nil
    end
  end

  defp start_new_manager(args) do
    result =
      DynamicSupervisor.start_child(
        Fastrepl.ThreadManagerSupervisor,
        {Fastrepl.ThreadManager, args}
      )

    case result do
      {:ok, pid} -> pid
      _ -> nil
    end
  end
end
