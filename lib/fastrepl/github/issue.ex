defmodule Fastrepl.Github.Issue do
  defstruct [:id, :node_id, :repo_full_name, :is_pr, :title, :number, :body, :url, :comments]

  alias Fastrepl.Github.Issue.Comment

  @type t :: %__MODULE__{
          id: integer(),
          node_id: String.t(),
          repo_full_name: String.t(),
          is_pr: boolean(),
          title: String.t(),
          number: String.t(),
          body: String.t(),
          url: String.t(),
          comments: [Comment.t()]
        }

  def from(repo_full_name, issue_number) do
    [owner, repo] = String.split(repo_full_name, "/")

    with {:ok, issue} <- GitHub.Issues.get(owner, repo, issue_number),
         {:ok, comments} <- Comment.list_from(repo_full_name, issue_number) do
      {:ok,
       %__MODULE__{
         id: issue.id,
         node_id: issue.node_id,
         repo_full_name: repo_full_name,
         is_pr: String.contains?(issue.html_url, "pull"),
         title: issue.title,
         number: issue.number,
         body: issue.body,
         url: issue.html_url,
         comments: comments
       }}
    else
      {:error, error} -> {:error, error}
    end
  end

  def from!(repo_full_name, issue_number) do
    {:ok, issue} = from(repo_full_name, issue_number)
    issue
  end

  def mock(title, body) do
    %__MODULE__{
      title: title,
      number: 1,
      body: body,
      url: "https://github.com/fastrepl/fastrepl/issues/1",
      comments: []
    }
  end

  def list_open(repo_full_name) do
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

  def list_open!(repo_full_name) do
    {:ok, result} = list_open(repo_full_name)
    result
  end

  def list_examples_per_label(repo_full_name, labels) do
    [owner, repo] = String.split(repo_full_name, "/")

    tasks =
      labels
      |> Enum.map(fn label ->
        Task.Supervisor.async_nolink(Fastrepl.TaskSupervisor, fn ->
          {:ok, issues} =
            GitHub.Issues.list_for_repo(
              owner,
              repo,
              page: 1,
              per_page: 3,
              labels: label
            )

          {label, issues}
        end)
      end)

    tasks
    |> Task.await_many(10_000)
    |> Enum.reject(fn {_, issues} -> Enum.empty?(issues) end)
  end

  def set_labels(%__MODULE__{} = issue, labels) do
    [owner, repo] = String.split(issue.repo_full_name, "/")

    GitHub.Issues.set_labels(owner, repo, issue.number, labels)
  end
end

defmodule Fastrepl.Github.Issue.Comment do
  defstruct [:id, :node_id, :repo_full_name, :body, :issue_url, :is_pr, :user_name]

  @type t :: %__MODULE__{
          id: integer(),
          node_id: String.t(),
          repo_full_name: String.t(),
          is_pr: boolean(),
          body: String.t(),
          issue_url: String.t(),
          user_name: String.t()
        }

  def from(comment, repo_full_name) do
    %__MODULE__{
      id: comment.id,
      node_id: comment.node_id,
      repo_full_name: repo_full_name,
      body: comment.body,
      issue_url: comment.html_url,
      is_pr: String.contains?(comment.html_url, "pull"),
      user_name: get_in(comment.user, [Access.key(:login, "Unknown")])
    }
  end

  def list_from(repo_full_name, issue_number) do
    [owner, repo] = String.split(repo_full_name, "/")

    case GitHub.Issues.list_comments(owner, repo, issue_number, page: 1, per_page: 50) do
      {:ok, comments} -> {:ok, Enum.map(comments, &from(&1, repo_full_name))}
      {:error, error} -> {:error, error}
    end
  end

  def create(repo_full_name, issue_number, body, opts \\ []) do
    [owner, repo] = String.split(repo_full_name, "/")

    case GitHub.Issues.create_comment(owner, repo, issue_number, %{body: body}, opts) do
      {:ok, comment} -> {:ok, from(comment, repo_full_name)}
      {:error, error} -> {:error, error}
    end
  end

  def update(%__MODULE__{} = comment, body) do
    [owner, repo] = String.split(comment.repo_full_name, "/")

    case GitHub.Issues.update_comment(owner, repo, comment.id, body) do
      {:ok, updated_comment} -> {:ok, from(updated_comment, comment.repo_full_name)}
      {:error, error} -> {:error, error}
    end
  end
end
