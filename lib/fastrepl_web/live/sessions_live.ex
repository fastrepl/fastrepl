defmodule FastreplWeb.SessionsLive do
  use FastreplWeb, :live_view

  import FastreplWeb.SessionComponents, only: [session_list_item: 1]

  def render(assigns) do
    ~H"""
    <div class="px-[15px] py-[20px]">
      <div class="flex flex-row items-center gap-2">
        <h2 class="text-xl font-semibold">Sessions</h2>
        <.svelte name="TicketEditor" socket={@socket} ssr={false} />
      </div>

      <ul class="flex flex-col gap-1 mt-8 max-w-[400px]">
        <%= for session <- @sessions do %>
          <li>
            <.session_list_item
              status={session.status}
              display_id={session.display_id}
              github_issue_number={session.github_issue_number}
              github_repo_full_name={session.github_repo_full_name}
            />
          </li>
        <% end %>
      </ul>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    sessions =
      socket.assigns.current_account
      |> Fastrepl.Sessions.list_sessions(limit: 30)
      |> Enum.map(fn session ->
        if session.ticket == nil do
          nil
        else
          %{
            status: session.status,
            display_id: session.display_id,
            github_issue_number: session.ticket.github_issue_number,
            github_repo_full_name: session.ticket.github_repo_full_name
          }
        end
      end)
      |> Enum.reject(&is_nil/1)

    {:ok, socket |> assign(:sessions, sessions)}
  end

  def handle_event("issue:submit", %{"content" => _content}, socket) do
    {:noreply, socket}
  end
end
