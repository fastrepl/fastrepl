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

  def create_issue(repo_full_name, opts \\ []) do
    url =
      "https://github.com/#{repo_full_name}/issues/new"
      |> URI.new!()

    opts
    |> Enum.reduce(url, fn {key, value}, acc ->
      %{key => value}
      |> URI.encode_query()
      |> then(&URI.append_query(acc, &1))
    end)
    |> URI.to_string()
  end

  def reference_file(repo_full_name, ref, path, line_start, line_end) do
    "https://github.com/#{repo_full_name}/blob/#{ref}/#{path}#L#{line_start}-L#{line_end}"
  end
end
