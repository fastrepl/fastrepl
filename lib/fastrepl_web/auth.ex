defmodule FastreplWeb.Auth do
  alias Phoenix.LiveView.Socket
  alias Fastrepl.Accounts
  import Phoenix.Component, only: [assign_new: 3]

  @default_account_name "Personal"

  @spec on_mount(term, map, map, Socket.t()) :: {:cont | :halt, Socket.t()}
  def on_mount(:fetch_or_create_account, _params, _session, socket) do
    {:cont, fetch_or_create_account(socket)}
  end

  defp fetch_or_create_account(socket) do
    current_user = socket.assigns[:current_user]

    current_account =
      case Accounts.list_accounts(current_user) do
        [account | _] ->
          account

        [] ->
          case Accounts.create_account(current_user, %{name: @default_account_name}) do
            {:ok, account} -> account
            _ -> nil
          end
      end

    if current_account do
      socket |> assign_new(:current_account, fn -> current_account end)
    else
      socket
    end
  end
end
