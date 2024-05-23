defmodule FastreplWeb.GithubWebhookPlug do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    handler = Keyword.fetch!(opts, :handler)

    case conn.method do
      "POST" ->
        {:ok, body, conn} = read_body(conn)

        params = Jason.decode!(body)

        event =
          conn
          |> Plug.Conn.get_req_header("x-github-event")
          |> Enum.at(0)

        Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
          apply(handler, :handle_event, [event, params])
        end)

        send_resp(conn, 200, "")

      _ ->
        send_resp(conn, 404, "Not Found")
    end
  end
end
