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
