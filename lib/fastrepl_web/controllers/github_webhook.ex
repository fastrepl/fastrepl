defmodule FastreplWeb.GithubWebhookHandler do
  use FastreplWeb, :controller
  require Logger

  alias Fastrepl.Github

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#installation
  def handle_event("installation", payload) do
    %{
      "action" => action,
      "installation" => %{"id" => installation_id},
      "repositories" => repos
    } = payload

    if action == "created" do
      app = Github.get_app_by_installation_id(installation_id)
      Github.set_repos(app, Enum.map(repos, & &1["full_name"]))
    end

    if action == "deleted" do
      Github.delete_app_by_installation_id(installation_id)
    end
  end

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#installation_repositories
  def handle_event("installation_repositories", payload) do
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
  def handle_event("issues", payload) do
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

  def handle_event(event, payload) do
    Logger.info("Unhandled event: #{event}, #{inspect(payload)}")
  end
end
