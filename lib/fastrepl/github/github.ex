defmodule Fastrepl.Github do
  @moduledoc """
  https://hexdocs.pm/oapi_github
  """

  def list_open_issues(repo_full_name) do
    [owner, repo] = String.split(repo_full_name, "/")

    GitHub.Issues.list_for_repo(
      owner,
      repo,
      page: 1,
      per_page: 20,
      state: "open",
      since: DateTime.utc_now() |> DateTime.add(-365, :day) |> DateTime.to_iso8601()
    )
  end

  def list_open_issues!(repo_full_name) do
    {:ok, result} = list_open_issues(repo_full_name)
    result
  end

  def get_installation_token!(installation_id) do
    {:ok, %{token: token}} =
      GitHub.Apps.create_installation_access_token(
        installation_id,
        %{},
        auth: GitHub.app(:fastrepl)
      )

    token
  end
end
