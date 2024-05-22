defmodule FastreplWeb.GithubWebhookController do
  use FastreplWeb, :controller
  require Logger

  alias Fastrepl.Github

  def index(conn, params) do
    event =
      conn
      |> Plug.Conn.get_req_header("x-github-event")
      |> Enum.at(0)

    Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
      handle_event(event, params, conn.assigns.current_account)
    end)

    conn |> send_resp(200, "")
  end

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#installation
  defp handle_event("installation", payload, current_account) do
    %{
      "action" => action,
      "installation" => %{"id" => installation_id},
      "repositories" => repos
    } = payload

    if action == "created" do
      Github.add_app(current_account, %{repo_full_names: Enum.map(repos, & &1["full_name"])})
    end

    if action == "deleted" do
      Github.delete_app_by_installation_id(installation_id)
    end
  end

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#installation_repositories
  defp handle_event("installation_repositories", payload, _current_account) do
    %{
      "action" => action,
      "installation" => %{"id" => _installation_id},
      "repositories_added" => _repositories_added,
      "repositories_removed" => _repositories_removed
    } = payload

    if action == "added" do
    end

    if action == "removed" do
    end
  end

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#issues
  defp handle_event("issues", payload, _current_account) do
    %{
      "action" => action,
      "installation" => %{"id" => _installation_id},
      "issue" => %{"number" => _number, "labels" => _labels},
      "repository" => %{"full_name" => _full_name}
    } = payload

    case action do
      "opened" ->
        :todo

      "closed" ->
        :todo

      "labeled" ->
        :todo

      "unlabeled" ->
        :todo
    end
  end

  defp handle_event(event, payload, _current_account) do
    Logger.info("Unhandled event: #{event}, #{inspect(payload)}")
  end
end
