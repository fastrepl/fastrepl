defmodule FastreplWeb.GithubWebhookHandler do
  require Logger

  alias Fastrepl.Github
  alias Fastrepl.Sessions

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#installation
  def handle_event("installation", payload) do
    %{
      "action" => action,
      "installation" => %{"id" => installation_id},
      "repositories" => repos
    } = payload

    case action do
      "created" ->
        repo_full_names = Enum.map(repos, & &1["full_name"])

        repo_full_names
        |> Enum.map(&Task.async(fn -> Github.Repo.create_label(&1, installation_id) end))
        |> Task.await_many()

        case Github.get_app_by_installation_id(installation_id) do
          nil ->
            # app is not yet created in the github_setup_live.
            # we create app here, and account will be linked there.
            Github.add_app(%{installation_id: installation_id, repo_full_names: repo_full_names})

          app ->
            # app already created in the github_setup_live.
            # we just need to update the repositories here.
            Github.update_app(app, %{repo_full_names: repo_full_names})
        end

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

    if app == nil do
      {:error, "app not found"}
    else
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
  end

  # https://docs.github.com/en/webhooks/webhook-events-and-payloads#issues
  def handle_event("issues", payload) do
    %{
      "action" => action,
      "installation" => %{"id" => installation_id},
      "issue" => %{"number" => issue_number, "labels" => labels},
      "repository" => %{"full_name" => repo_full_name}
    } = payload

    case Github.get_app_by_installation_id(installation_id) do
      nil ->
        {:error, "app not found"}

      app ->
        auth = Github.get_installation_token!(installation_id)

        {:ok, ticket} =
          Sessions.ticket_from(
            %{github_repo_full_name: repo_full_name, github_issue_number: issue_number},
            auth: auth
          )

        case action do
          action when action in ["labeled"] ->
            if has_fastrepl_label?(labels) do
              start_thread_manager(%{
                account_id: app.account_id,
                thread_id: Nanoid.generate(),
                ticket: ticket
              })
            end

          _ ->
            :ok
        end
    end
  end

  def handle_event(event, _payload) do
    {:error, %{type: :unhandled, event: event}}
  end

  defp has_fastrepl_label?(labels) do
    labels |> Enum.any?(&(&1["name"] == "fastrepl"))
  end

  defp start_thread_manager(args) do
    DynamicSupervisor.start_child(
      Fastrepl.ThreadManagerSupervisor,
      {Fastrepl.ThreadManager, args}
    )
  end
end
