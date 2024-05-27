defmodule Fastrepl.Github.Repo do
  defstruct [
    :owner_name,
    :repo_name,
    :full_name,
    :description,
    :default_branch,
    :default_branch_head,
    :base_branch,
    :base_commit
  ]

  alias Fastrepl.Github
  alias GitHub.Repos, as: Repo

  def from(repo_full_name, opts \\ []) do
    [owner_name, repo_name] = String.split(repo_full_name, "/")

    with {:ok, repo} <- Repo.get(owner_name, repo_name, opts),
         {:ok, branch} <- Repo.get_branch(owner_name, repo_name, repo.default_branch, opts) do
      {:ok,
       %__MODULE__{
         owner_name: owner_name,
         repo_name: repo_name,
         full_name: repo_full_name,
         description: repo.description,
         default_branch: repo.default_branch,
         default_branch_head: branch.commit.sha,
         base_branch: Keyword.get(opts, :base_branch, repo.default_branch),
         base_commit: Keyword.get(opts, :base_commit, branch.commit.sha)
       }}
    else
      {:error, error} -> {:error, error}
    end
  end

  def from!(repo_full_name, opts \\ []) do
    {:ok, repo} = from(repo_full_name, opts)
    repo
  end

  def get_commit_diff(repo_full_name, commit_hash) do
    [owner, repo] = String.split(repo_full_name, "/")

    result =
      GitHub.Repos.get_commit(
        owner,
        repo,
        commit_hash,
        request_headers: [{"Accept", "application/vnd.github.diff"}]
      )

    case result do
      {:ok, diff} -> diff
      _ -> ""
    end
  end

  def get_file_content(repo_full_name, path, ref) do
    [owner, repo] = String.split(repo_full_name, "/")

    case GitHub.Repos.get_content(owner, repo, path, ref: ref) do
      {:ok, %{content: content}} -> decode_content(content)
      _ -> ""
    end
  end

  def get_readme_content(repo_full_name) do
    [owner, repo] = String.split(repo_full_name, "/")

    case GitHub.Repos.get_readme(owner, repo) do
      {:ok, %{content: content}} -> decode_content(content)
      _ -> ""
    end
  end

  defp decode_content(content) do
    content
    |> String.split("\n")
    |> Enum.map(&Base.decode64!/1)
    |> Enum.join("")
  end

  def create_label(repo_full_name, installation_id) do
    [owner, repo] = String.split(repo_full_name, "/")
    token = Github.get_installation_token!(installation_id)

    body = %{
      name: "fastrepl",
      color: "C5DEF5"
    }

    GitHub.Issues.create_label(owner, repo, body, auth: token)
  end

  def list_labels(repo_full_name) do
    [owner, repo] = String.split(repo_full_name, "/")

    case GitHub.Issues.list_labels_for_repo(owner, repo, per_page: 100, page: 1) do
      {:ok, labels} -> labels |> Enum.map(& &1.name)
      _ -> []
    end
  end
end
