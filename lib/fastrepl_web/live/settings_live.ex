defmodule FastreplWeb.SettingsLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Github
  alias Fastrepl.Accounts

  import FastreplWeb.GithubComponents, only: [repo_list_item: 1]

  def render(assigns) do
    ~H"""
    <div>
      <h2 class="text-xl font-semibold">Settings</h2>

      <div class="mt-8">
        <div class="flex items-center gap-2" phx-click={show_modal("team_modal")}>
          <h3 class="text-lg font-semibold">Teams</h3>
          <%!-- <span class="hero-plus text-gray-700 hover:text-black w-4 h-4" /> --%>
        </div>

        <.modal id="team_modal">
          <.form :let={f} for={@account_form} phx-submit="new_account" class="mb-4 w-[400px]">
            <div class="flex items-center gap-1">
              <.input field={f[:name]} type="text" placeholder="New team name" class="w-full" />
              <.button
                type="submit"
                class="bg-blue-500 hover:bg-blue-600 px-4 py-2 rounded mt-2"
                phx-click={hide_modal("team_modal")}
              >
                Add
              </.button>
            </div>
          </.form>
        </.modal>

        <div :if={!@accounts.loading and @accounts.result == []}>
          <p>You don't have any teams yet.</p>
        </div>

        <div class="w-[200px]">
          <.input
            type="select"
            name="account"
            value={@current_account.name}
            options={if @accounts.loading, do: [], else: Enum.map(@accounts.result, & &1.name)}
          />
        </div>

        <h3 class="text-lg font-semibold mt-8">
          Plan
        </h3>
        <p>
          You are currently on the <strong>Free</strong> plan.
        </p>
        <.link
          href={~p"/checkout/session?a=1&i=0"}
          class="text-blue-500 font-semibold hover:underline"
        >
          Subscribe
        </.link>
        to our <strong>Pro</strong>
        plan to get access to more features.
      </div>

      <h3 class="text-lg font-semibold mt-8">GitHub</h3>
      You can
      <.link
        target="_blank"
        class="text-blue-500 font-semibold hover:underline"
        href={@github_app_url}
      >
        install
      </.link>
      our Github app to get access to your repositories.
      <ul
        :if={!@github_repos.loading}
        class="flex flex-col gap-1 max-w-[400px] max-h-[300px] overflow-y-auto mt-4"
      >
        <li :for={repo <- @github_repos.result}>
          <.repo_list_item repo_full_name={repo} />
        </li>
      </ul>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    current_user = socket.assigns.current_user
    current_account = socket.assigns.current_account

    socket =
      socket
      |> assign(:show_team_modal, false)
      |> assign(:current_account, current_account)
      |> assign(:account_form, to_form(%{"name" => current_account.name}))
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
