defmodule FastreplWeb.GitPatchController do
  use FastreplWeb, :controller

  def view(conn, %{"id" => id}) do
    patch =
      case Fastrepl.Temp.get(id) do
        {:ok, content} -> content
        _ -> ""
      end

    command = "curl #{FastreplWeb.Endpoint.url()}" <> "/patch/#{id} | git apply"

    render(conn, :view, layout: false, command: command, patch: patch)
  end

  @spec api(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def api(conn, %{"id" => id}) do
    case Fastrepl.Temp.get(id) do
      {:ok, patch} -> send_resp(conn, 200, patch)
      _ -> send_resp(conn, 404, "")
    end
  end
end
