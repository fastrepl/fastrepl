defmodule FastreplWeb.Auth do
  alias Phoenix.LiveView.Socket
  alias Fastrepl.Accounts
  import Phoenix.Component, only: [assign_new: 3]

  @spec on_mount(term, map, map, Socket.t()) :: {:cont | :halt, Socket.t()}
  def on_mount(:fetch_account, _params, _session, socket) do
    {:cont, fetch_account(socket)}
  end

  defp fetch_account(socket) do
    if socket.assigns[:current_user] do
      socket
      |> assign_new(:current_account, fn ->
        Accounts.list_accounts(socket.assigns[:current_user]) |> Enum.at(0, nil)
      end)
    else
      socket
    end
  end
end
