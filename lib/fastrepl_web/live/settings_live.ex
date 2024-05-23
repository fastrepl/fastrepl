defmodule FastreplWeb.SettingsLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Github
  alias Fastrepl.Accounts

  def render(assigns) do
    ~H"""
    <div class="mx-auto max-w-3xl">
      <h2 class="text-xl font-semibold">Settings</h2>

      <div class="mt-4">
        <h3 class="text-lg font-semibold">Teams</h3>
        <div :if={@accounts.loading}>...</div>
        <div :if={!@accounts.loading and @accounts.result == []}>
          <p>You don't have any teams yet.</p>
        </div>

        <.form :let={f} for={@account_form} phx-submit="new_account" class="mb-4">
          <div class="flex items-center gap-1">
            <.input field={f[:name]} type="text" placeholder="New team name" class="w-full" />
            <.button type="submit" class="bg-blue-500 hover:bg-blue-600 px-4 py-2 rounded mt-2">
              Add
            </.button>
          </div>
        </.form>

        <ul :if={!@accounts.loading}>
          <li :for={account <- @accounts.result}>
            <span><%= account.name %></span>
          </li>
        </ul>

        <h3 class="text-lg font-semibold mt-4">Integrations</h3>
        <h4 class="text-md font-semibold mt-4">GitHub</h4>
        You can
        <.link
          target="_blank"
          class="text-blue-500 font-semibold hover:underline"
          href={@github_app_url}
        >
          install
        </.link>
        our Github app to get access to your repositories.
        <ul :if={!@github_repos.loading}>
          <li :for={repo <- @github_repos.result}>
            <span><%= repo %></span>
          </li>
        </ul>

        <h4 class="text-md font-semibold mt-4">Linear</h4>
        <p>Coming soon...</p>

        <h3 class="text-lg font-semibold mt-4">Pro</h3>
        <.link
          href={~p"/checkout/session?a=1&i=0"}
          class="text-blue-500 font-semibold hover:underline"
        >
          Link
        </.link>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    current_account = socket.assigns.current_account

    socket =
      socket
      |> assign(:account_form, to_form(%{"name" => ""}))
      |> assign(:github_app_url, Application.fetch_env!(:fastrepl, :github_app_url))
      |> assign_async(:github_repos, fn ->
        repos = if(current_account, do: Github.list_installed_repos(current_account), else: [])
        {:ok, %{github_repos: repos}}
      end)
      |> assign_async(:accounts, fn ->
        {:ok, %{accounts: Accounts.list_accounts(current_user)}}
      end)

    {:ok, socket}
  end

  def handle_event("new_account", %{"name" => name}, socket) do
    current_user = socket.assigns.current_user

    socket =
      case Accounts.create_account(current_user, %{name: name}) do
        {:ok, _account} ->
          socket
          |> assign(:account_form, to_form(%{"name" => ""}))
          |> assign_async(:accounts, fn ->
            accounts = Accounts.list_accounts(current_user)
            {:ok, %{accounts: accounts}}
          end)

        {:error, changeset} ->
          socket |> assign(:account_form, to_form(changeset))
      end

    {:noreply, socket}
  end
end
