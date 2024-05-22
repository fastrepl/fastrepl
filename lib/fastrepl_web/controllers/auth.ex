defmodule FastreplWeb.AuthController do
  use FastreplWeb, :controller

  import Identity.Plug

  def login(conn, _params) do
    render(conn, :login, layout: false)
  end

  def logout(conn, _params) do
    conn
    |> log_out_user()
    |> redirect(to: "/")
  end
end
