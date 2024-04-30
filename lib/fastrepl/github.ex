defmodule Fastrepl.Github do
  @moduledoc """
  https://hexdocs.pm/oapi_github
  """

  def get_repo(full_name) do
    [owner, repo] = String.split(full_name, "/")
    GitHub.Repos.get(owner, repo)
  end

  def get_repo!(full_name) do
    {:ok, repo} = get_repo(full_name)
    repo
  end

  def get_issue(repo_full_name, issue_number) do
    [owner, repo] = String.split(repo_full_name, "/")
    GitHub.Issues.get(owner, repo, issue_number)
  end

  def get_issue!(repo_full_name, issue_number) do
    {:ok, result} = get_issue(repo_full_name, issue_number)
    result
  end

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

  def list_issue_comments(repo_full_name, issue_number) do
    [owner, repo] = String.split(repo_full_name, "/")
    GitHub.Issues.list_comments(owner, repo, issue_number, page: 1, per_page: 50)
  end

  def list_issue_comments!(repo_full_name, issue_number) do
    {:ok, result} = list_issue_comments(repo_full_name, issue_number)
    result
  end

  def get_latest_commit(repository) do
    [owner, repo] = String.split(repository.full_name, "/")
    branch_name = repository.default_branch

    {:ok, branch} = GitHub.Repos.get_branch(owner, repo, branch_name)
    branch.commit.sha
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

defmodule Fastrepl.Github.URL do
  def clone_without_token(repo_full_name) do
    "https://github.com/#{repo_full_name}.git"
  end

  def clone_with_token(repo_full_name, token) do
    "https://x-access-token:#{token}@github.com/#{repo_full_name}.git"
  end

  def diff_pr(repo_full_name, pr_number) do
    "https://github.com/#{repo_full_name}/pull/#{pr_number}.diff"
  end

  def diff_between(repo_full_name, branch_or_commit1, branch_or_commit2) do
    "https://github.com/#{repo_full_name}/compare/#{branch_or_commit1}...#{branch_or_commit2}.diff"
  end

  def commit(repo_full_name, commit) do
    "https://github.com/#{repo_full_name}/commit/#{commit}"
  end

  def pr(repo_full_name, pr_number) do
    "https://github.com/#{repo_full_name}/pull/#{pr_number}"
  end

  def issue(repo_full_name, issue_numner) do
    "https://github.com/#{repo_full_name}/issues/#{issue_numner}"
  end
end
