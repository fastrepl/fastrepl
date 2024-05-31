defmodule Fastrepl.PullRequest.Summary do
  use Oban.Worker,
    queue: :pr,
    unique: [
      fields: [:args],
      keys: [:github_repo_full_name, :github_issue_number],
      states: [
        :available,
        :scheduled,
        :retryable
      ],
      period: :infinity
    ],
    replace: [
      available: [:args, :scheduled_at],
      scheduled: [:args, :scheduled_at],
      retryable: [:args, :scheduled_at]
    ]

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    impl(args)
  end

  @summary_regex ~r/<details by="fastrepl">.*?<\/details>/s

  defp impl(%{
         "github_repo_full_name" => github_repo_full_name,
         "github_issue_number" => github_issue_number,
         "installation_id" => installation_id
       }) do
    [owner, repo] = String.split(github_repo_full_name, "/")

    with {:ok, token} <- Fastrepl.Github.get_installation_token(installation_id),
         {:ok, pr} <- get_pr(owner, repo, github_issue_number, token),
         {:ok, commits} <- get_commits(owner, repo, github_issue_number, token),
         {:ok, comment} <- write_comment(pr, commits) do
      updated_pr_body =
        case Regex.run(@summary_regex, pr.body) do
          nil -> pr.body <> "\n\n" <> comment
          [_] -> Regex.replace(@summary_regex, pr.body, comment)
        end

      GitHub.Pulls.update(
        owner,
        repo,
        github_issue_number,
        %{body: updated_pr_body},
        auth: token
      )
    end
  end

  defp get_pr(owner, repo, issue_number, token) do
    case GitHub.Pulls.get(owner, repo, issue_number, auth: token) do
      {:ok, pr} ->
        {:ok, %{title: pr.title, body: Regex.replace(@summary_regex, pr.body || "", "")}}

      {:error, error} ->
        {:error, error}
    end
  end

  defp get_commits(owner, repo, issue_number, token) do
    case GitHub.Pulls.list_commits(owner, repo, issue_number, auth: token) do
      {:ok, commits} ->
        commits =
          commits
          |> Enum.map(fn %{sha: sha} -> sha end)
          |> Enum.map(fn sha ->
            case GitHub.Repos.get_commit(owner, repo, sha, auth: token) do
              {:ok, %{commit: %{message: message}, files: files}} ->
                %{
                  message: message,
                  files: files |> Enum.map(&Map.take(&1, [:filename, :patch]))
                }

              _ ->
                nil
            end
          end)
          |> Enum.reject(&is_nil/1)

        {:ok, commits}

      {:error, error} ->
        {:error, error}
    end
  end

  defp write_comment(pr, commits) do
    user_content = """
    Here's the information about the pull request:

    <pr_title>
    #{pr.title}
    </pr_title>

    <pr_body>
    #{pr.body}
    </pr_body>
    """

    user_content =
      commits
      |> Enum.reduce(user_content, fn %{message: message, files: files}, acc ->
        files_rendered =
          files
          |> Enum.map(fn %{filename: filename, patch: patch} ->
            """
            <commit_file>
            <commit_file_name>
            #{filename}
            </commit_file_name>

            <commit_file_patch>
            #{patch}
            </commit_file_patch>
            </commit_file>
            """
            |> String.trim()
          end)
          |> Enum.join("\n")

        commit_rendered =
          """
          <commit>
          <commit_message>
          #{message}
          </commit_message>

          <commit_files>
          #{files_rendered}
          </commit_files>
          </commit>
          """
          |> String.trim()

        acc <> "\n\n" <> commit_rendered
      end)

    result =
      Fastrepl.AI.chat(%{
        model: "gpt-4o",
        stream: false,
        temperature: 0.2,
        messages: [
          %{
            role: "system",
            content: """
            You are a senior software engineer with extensive experience in leading open source projects.
            The user will provide you a information about the pull request. You should summarize the pull request and its changes.

            Your response should be valid, rich markdown that Github supports. Use backticks(``) for variable, filenames, package name, etc.
            Only use `### Description` and `#### Changes` sections. ``### Description` should be one-liner describing "What" the PR is about.
            ``#### Changes` should be a list of descriptions of each main change. Each item in list should be very concise and short, and should not have child list.

            At the high level, it should look like this:

            ### Description
            This PR ~

            #### Changes
            - Updated ~
            """
          },
          %{
            role: "user",
            content: user_content
          }
        ]
      })

    case result do
      {:ok, content} ->
        comment =
          """
          <details by="fastrepl">
          <summary>For reviewers</summary>

          #{content}
          ---
          _Generated by [Fastrepl](https://github.com/fastrepl/fastrepl)_
          </details>
          """
          |> String.trim()

        {:ok, comment}

      {:error, error} ->
        {:error, error}
    end
  end
end
