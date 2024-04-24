defmodule FastreplWeb.GithubAuth do
  import Plug.Conn

  alias Assent.{Config, Strategy.Github}

  # http://localhost:4000/auth/github
  def request(conn) do
    Application.get_env(:assent, :github)
    |> Github.authorize_url()
    |> case do
      {:ok, %{url: url, session_params: session_params}} ->
        conn
        |> put_session(:session_params, session_params)
        |> put_resp_header("location", url)
        |> send_resp(302, "")

      {:error, error} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(
          500,
          "Something went wrong generating the request authorization url: #{inspect(error)}"
        )
    end
  end

  # http://localhost:4000/auth/github/callback
  def callback(conn) do
    %{params: params} = fetch_query_params(conn)
    session_params = get_session(conn, :session_params)

    Application.get_env(:assent, :github)
    |> Config.put(:session_params, session_params)
    |> Github.callback(params)
    |> case do
      {:ok, %{user: user, token: token}} ->
        conn
        |> put_session(:github_user, user)
        |> put_session(:github_user_token, token)
        |> Phoenix.Controller.redirect(to: "/")

      {:error, error} ->
        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(500, inspect(error, pretty: true))
    end
  end

  def fetch_github_user(conn, _opts) do
    with user when is_map(user) <- get_session(conn, :github_user) do
      assign(conn, :current_user, %{email: user["email"]})
    else
      _ -> conn
    end
  end

  def on_mount(:mount_current_user, _params, session, socket) do
    {:cont, mount_current_user(socket, session)}
  end

  defp mount_current_user(socket, session) do
    Phoenix.Component.assign_new(socket, :current_user, fn ->
      if user = session["github_user"] do
        %{email: user["email"]}
      end
    end)
  end
end
