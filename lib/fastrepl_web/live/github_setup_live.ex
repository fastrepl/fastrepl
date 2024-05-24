defmodule FastreplWeb.GithubSetupLive do
  use FastreplWeb, :live_view

  alias Fastrepl.Github
  alias Fastrepl.Accounts
  alias Fastrepl.Accounts.Account

  def render(assigns) do
    ~H"""
    <%= if @installation_id do %>
      <h1 class="text-2xl font-semibold mb-2">
        Github app installed!
      </h1>

      <p class="mt-12">Which account do you want to link?</p>
      <div class="flex gap-4 items-center">
        <.form
          for={@form}
          phx-submit="save"
          phx-change="change_account"
          class="flex flex-row gap-2 items-center"
        >
          <.input
            type="select"
            name="account"
            field={@form[:account]}
            options={if @accounts.loading, do: [], else: @accounts.result}
          />
          <.button type="submit" class="py-1 mt-2">Save</.button>
        </.form>
      </div>
    <% else %>
      <h1 :if={!@installation_id} class="text-2xl font-semibold mb-2">
        There's something wrong with your Github app installation.
      </h1>
    <% end %>
    """
  end

  def mount(params, _session, socket) do
    current_user = socket.assigns.current_user

    socket =
      socket
      |> assign(form: to_form(%{"account" => socket.assigns.current_account.name}))
      |> assign(installation_id: params["installation_id"])
      |> assign_async(:accounts, fn ->
        accounts =
          Accounts.list_accounts(current_user)
          |> Enum.map(fn %Account{name: name} -> name end)

        {:ok, %{accounts: accounts}}
      end)

    {:ok, socket}
  end

  def handle_event("change_account", %{"account" => account_name}, socket) do
    socket =
      socket
      |> assign(:form, to_form(%{"account" => account_name}))
      |> assign(
        :current_account,
        Accounts.get_account_by_name(socket.assigns.current_user, account_name)
      )

    {:noreply, socket}
  end

  def handle_event("save", _params, socket) do
    result =
      Github.add_app(
        socket.assigns.current_account,
        %{installation_id: socket.assigns.installation_id}
      )

    socket =
      case result do
        {:ok, _} ->
          socket
          |> redirect(to: "/setting")
          |> put_flash(:info, "Github app installed!")

        _ ->
          socket
          |> put_flash(:error, "Something went wrong!")
      end

    {:noreply, socket}
  end
end
