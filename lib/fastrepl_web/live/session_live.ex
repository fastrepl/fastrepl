defmodule FastreplWeb.SessionLive do
  use FastreplWeb, :live_view

  import FastreplWeb.SessionComponents, only: [github_issue: 1, github_repo: 1]

  def render(assigns) do
    ~H"""
    <div class="bg-gray-50 rounded-md">
      <%= case assigns[:status] do %>
        <% :init -> %>
          <div class="flex flex-row gap-2 items-center justify-center h-[calc(100vh-90px)]">
            <span>We are now working on</span>
            <.github_issue
              name={@ticket.github_repo.full_name}
              title={@ticket.github_issue.title}
              number={@ticket.github_issue.number}
            />
            <span>in</span>
            <.github_repo
              name={@ticket.github_repo.full_name}
              sha={@ticket.github_repo.default_branch_head}
              description={@ticket.github_repo.description}
            />
            <span>...</span>
          </div>
        <% :done -> %>
          <div class="flex flex-row gap-2 items-center justify-center h-[calc(100vh-90px)]">
            <span>This session is terminated.</span>
          </div>
        <% _ -> %>
          <.svelte
            name="Session"
            socket={@socket}
            ssr={false}
            props={
              %{
                repoFullName: @ticket.github_repo.full_name,
                paths: @paths,
                originalFiles: @original_files,
                currentFiles: @current_files,
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

  def mount(%{"id" => session_id}, _session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(Fastrepl.PubSub, "session:#{session_id}")
    end

    case find_or_start_manager(%{
           account_id: socket.assigns.current_account.id,
           session_id: session_id
         }) do
      {:ok, pid} ->
        existing_state = GenServer.call(pid, :init_state, 10 * 1000)

        default_state = %{
          manager_pid: pid,
          session_id: session_id,
          paths: [],
          original_files: [],
          current_files: [],
          comments: [],
          patches: []
        }

        state = Map.merge(default_state, existing_state)
        {:ok, socket |> assign(state)}

      {:error, _} ->
        socket =
          socket
          |> put_flash(:error, "You don't have access to this session or something went wrong.")
          |> redirect(to: "/sessions")

        {:ok, socket}
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

  def handle_event("file:update", %{"path" => path, "content" => content}, socket) do
    file = %Fastrepl.FS.File{path: path, content: content}
    :ok = GenServer.call(socket.assigns.manager_pid, {:file_update, file})
    {:noreply, socket}
  end

  def handle_event("execute", %{}, socket) do
    :ok = GenServer.call(socket.assigns.manager_pid, :execute)
    {:noreply, socket}
  end

  def handle_event("patch:download", %{}, socket) do
    id = Nanoid.generate()
    patch = socket.assigns.patches |> Enum.map(& &1.content) |> Enum.join("\n")

    :ok = Fastrepl.Temp.set(id, patch, ttl: 100)
    url = FastreplWeb.Endpoint.url() <> "/patch/view/#{id}"

    {:reply, %{url: url}, socket}
  end

  def handle_event("comments:share", %{}, socket) do
    reply =
      case GenServer.call(socket.assigns.manager_pid, :comments_share, 12 * 1000) do
        {:ok, url} -> %{url: url}
        _ -> %{url: ""}
      end

    {:reply, reply, socket}
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

  defp find_or_start_manager(%{account_id: _, session_id: _} = args) do
    existing = find_existing_manager(args)
    if existing == nil, do: start_new_manager(args), else: existing
  end

  defp find_existing_manager(%{account_id: account_id, session_id: session_id}) do
    registry = Application.fetch_env!(:fastrepl, :session_manager_registry)

    case Registry.lookup(registry, session_id) do
      [{pid, %{account_id: ^account_id}}] when is_pid(pid) -> {:ok, pid}
      [{pid, _value}] when is_pid(pid) -> {:error, :unauthorized}
      [] -> nil
    end
  end

  defp start_new_manager(args) do
    result =
      DynamicSupervisor.start_child(
        Fastrepl.SessionManagerSupervisor,
        {Fastrepl.SessionManager, args}
      )

    case result do
      {:ok, pid} -> {:ok, pid}
      {:error, error} -> {:error, error}
    end
  end
end
