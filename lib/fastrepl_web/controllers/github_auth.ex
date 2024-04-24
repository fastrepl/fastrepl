defmodule FastreplWeb.GithubAuthController do
  use FastreplWeb, :controller

  alias FastreplWeb.GithubAuth

  def request(conn, _params) do
    GithubAuth.request(conn)
  end

  def callback(conn, _params) do
    GithubAuth.callback(conn)
  end
end
