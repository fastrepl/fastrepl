defmodule Fastrepl.Github.Issue do
  defstruct [:is_pr, :title, :number, :body, :url, :comments]

  alias Fastrepl.Github.Issue.Comment

  @type t :: %__MODULE__{
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
         {:ok, comments} <- Comment.from(repo_full_name, issue_number) do
      {:ok,
       %__MODULE__{
         title: issue.title,
         number: issue.number,
         body: issue.body,
         url: issue.html_url,
         is_pr: String.contains?(issue.html_url, "pull"),
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
end

defmodule Fastrepl.Github.Issue.Comment do
  defstruct [:is_pr, :body, :issue_url, :user_name]

  @type t :: %__MODULE__{
          is_pr: boolean(),
          body: String.t(),
          issue_url: String.t(),
          user_name: String.t()
        }

  def from(repo_full_name, issue_number) do
    [owner, repo] = String.split(repo_full_name, "/")

    case GitHub.Issues.list_comments(owner, repo, issue_number, page: 1, per_page: 50) do
      {:ok, comments} ->
        comments =
          comments
          |> Enum.map(fn comment ->
            %__MODULE__{
              body: comment.body,
              issue_url: comment.html_url,
              is_pr: String.contains?(comment.html_url, "pull"),
              user_name: comment.user.login
            }
          end)

        {:ok, comments}

      {:error, error} ->
        {:error, error}
    end
  end
end
