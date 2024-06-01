defmodule FastreplWeb.SettingsLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Github
  alias Fastrepl.Accounts

  import FastreplWeb.GithubComponents, only: [repo_list_item: 1]

  def render(assigns) do
    ~H"""
    <div class="px-[15px] py-[20px]">
      <h2 class="text-xl font-semibold mb-8">Settings</h2>

      <ul class="flex flex-col gap-8">
        <li>
          <h3 class="text-lg font-semibold">Teams</h3>

          <div class="w-[200px]">
            <.input
              type="select"
              name="account"
              value={@current_account.name}
              options={if @accounts.loading, do: [], else: Enum.map(@accounts.result, & &1.name)}
            />
          </div>
        </li>

        <li>
          <div class="flex items-center gap-2" phx-click={show_modal("member_modal")}>
            <h3 class="text-lg font-semibold">Members</h3>
            <span class="hero-plus text-gray-700 hover:text-black w-4 h-4" />
          </div>

          <.modal id="member_modal">
            <.form :let={f} for={@member_form} phx-submit="invite_member" class="w-full">
              <div class="flex items-center gap-1 w-full">
                <.input field={f[:email]} type="email" placeholder="New member email" />
                <.button
                  type="submit"
                  class="bg-blue-500 hover:bg-blue-600 px-4 py-2 rounded mt-2"
                  phx-click={hide_modal("member_modal")}
                >
                  Invite
                </.button>
              </div>
            </.form>
          </.modal>

          <ul :if={!@members.loading} class="flex flex-col gap-0.5">
            <li :for={member <- @members.result}>
              <span>
                <%= member.login %>
              </span>
            </li>
          </ul>
        </li>

        <li>
          <h3 class="text-lg font-semibold">GitHub</h3>
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
            class="flex flex-col gap-1 max-w-[400px] max-h-[300px] mt-4 overflow-y-hidden hover:overflow-y-auto"
          >
            <li :for={repo <- @github_repos.result}>
              <.repo_list_item repo_full_name={repo} />
            </li>
          </ul>
        </li>

        <li>
          <h3 class="text-lg font-semibold">
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
      |> assign(:current_account, current_account)
      |> assign(:member_form, to_form(%{"email" => ""}))
      |> assign(:github_app_url, Application.fetch_env!(:fastrepl, :github_app_url))
      |> assign_async(:members, fn ->
        members =
          current_account
          |> Accounts.list_members()
          |> Enum.map(&get_in(&1.user.oauth_logins, [Access.at(0), Access.key(:token)]))
          |> Enum.map(&GitHub.Users.get_authenticated(auth: &1))
          |> Enum.map(fn {:ok, user} -> Map.take(user, [:login]) end)

        {:ok, %{members: members}}
      end)
      |> assign_async(:github_repos, fn ->
        repos = if(current_account, do: Github.list_installed_repos(current_account), else: [])
        {:ok, %{github_repos: repos}}
      end)
      |> assign_async(:accounts, fn ->
        {:ok, %{accounts: Accounts.list_accounts(current_user)}}
      end)

    {:ok, socket}
  end

  def handle_event("invite_member", %{"email" => email}, socket) do
    current_account = socket.assigns.current_account

    key = Nanoid.generate()
    url = FastreplWeb.Endpoint.url() <> "/invite/#{key}"

    socket =
      with :ok <- Fastrepl.Temp.set(key, current_account.id, ttl: 60 * 5),
           {:ok, _} <- Fastrepl.UserNotifier.deliver_invite_link(email, %{url: url}) do
        socket |> put_flash(:info, "Invitation email sent.")
      else
        _ -> socket |> put_flash(:error, "Failed send invitation email.")
      end

    {:noreply, socket}
  end
end
