defmodule FastreplWeb.ThreadLive do
  use FastreplWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="w-full h-[calc(100vh-140px)] bg-gray-50 rounded-md">
      <p :if={assigns[:status]}>
        <%= @status %>
      </p>

      <p :if={assigns[:github_repo]}>
        <%= @github_repo.full_name %>
      </p>
      <p :if={assigns[:github_issue]}>
        <%= @github_issue.title %>
      </p>
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

      pid when is_pid(pid) ->
        state = GenServer.call(pid, :state)
        send(self(), {:sync, state})

        {:ok, socket |> assign(manager_pid: pid, thread_id: thread_id)}
    end
  end

  def handle_info({:sync, state}, socket) do
    {:noreply, socket |> assign(state)}
  end

  defp find_existing_manager(thread_id) do
    registry = Application.fetch_env!(:fastrepl, :thread_manager_registry)

    case Registry.lookup(registry, thread_id) do
      [{pid, _value}] -> pid
      [] -> nil
    end
  end
end
