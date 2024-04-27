defmodule FastreplWeb.GithubAuthController do
  use FastreplWeb, :controller

  alias FastreplWeb.GithubAuth

  def sign_in(conn, _params) do
    GithubAuth.sign_in(conn)
  end

  def sign_out(conn, _params) do
    GithubAuth.sign_out(conn)
  end

  def callback(conn, _params) do
    GithubAuth.callback(conn)
  end
end
