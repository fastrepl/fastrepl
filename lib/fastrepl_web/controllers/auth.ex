defmodule FastreplWeb.AuthController do
  use FastreplWeb, :controller

  import Identity.Plug
  alias Fastrepl.Temp
  alias Fastrepl.Accounts

  def login(conn, _params) do
    render(conn, :login, layout: false)
  end

  def logout(conn, _params) do
    conn
    |> log_out_user()
    |> redirect(to: "/")
  end

  def invite(conn, %{"key" => key}) do
    case Temp.get(key) do
      {:ok, account_id} ->
        account = Accounts.get_account_by_id(account_id)

        if account == nil do
          conn
          |> put_flash(:error, "Invalild invitation link.")
          |> redirect(to: "/")
        else
          case Accounts.add_member(account, conn.assigns.current_user) do
            {:ok, _} ->
              conn
              |> put_flash(:info, "Invitation accepted!")
              |> redirect(to: "/settings")

            {:error, _} ->
              conn
              |> put_flash(:error, "Failed to process invitation.")
              |> redirect(to: "/")
          end
        end

      _ ->
        conn
        |> put_flash(:error, "Invitation link expired.")
        |> redirect(to: "/")
    end
  end
end
