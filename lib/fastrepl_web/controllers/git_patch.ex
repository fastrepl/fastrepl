defmodule FastreplWeb.GitPatchController do
  use FastreplWeb, :controller

  def patch(conn, %{"id" => id}) do
    case find_existing_orchestrator(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, "")

      pid ->
        patch = GenServer.call(pid, :patch)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, patch)
    end
  end

  defp find_existing_orchestrator(thread_id) do
    registry = Application.fetch_env!(:fastrepl, :orchestrator_registry)

    case Registry.lookup(registry, thread_id) do
      [{pid, _value}] -> pid
      [] -> nil
    end
  end
end
