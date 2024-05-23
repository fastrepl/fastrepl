defmodule FastreplWeb.GithubWebhookHandler do
  alias Fastrepl.Github

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#installation
  def handle_event("installation", payload) do
    %{
      "action" => action,
      "installation" => %{"id" => installation_id},
      "repositories" => repos
    } = payload

    case action do
      "created" ->
        app = Github.get_app_by_installation_id(installation_id)
        Github.set_repos(app, Enum.map(repos, & &1["full_name"]))

      "deleted" ->
        Github.delete_app_by_installation_id(installation_id)
    end
  end

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#installation_repositories
  def handle_event("installation_repositories", payload) do
    %{
      "action" => action,
      "installation" => %{"id" => installation_id},
      "repositories_added" => repositories_added,
      "repositories_removed" => repositories_removed
    } = payload

    app = Github.get_app_by_installation_id(installation_id)

    repos =
      case action do
        "added" ->
          existing = app.repo_full_names |> MapSet.new()
          added = repositories_added |> Enum.map(& &1["full_name"]) |> MapSet.new()
          MapSet.union(existing, added) |> MapSet.to_list()

        "removed" ->
          existing = app.repo_full_names |> MapSet.new()
          removed = repositories_removed |> Enum.map(& &1["full_name"]) |> MapSet.new()
          MapSet.difference(existing, removed) |> MapSet.to_list()
      end

    Github.set_repos(app, repos)
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
      "opened" -> :ok
      "closed" -> :ok
      "labeled" -> :ok
      "unlabeled" -> :ok
    end
  end

  def handle_event(event, _payload) do
    {:error, %{type: :unhandled, event: event}}
  end
end
