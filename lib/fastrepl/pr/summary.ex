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

  @fastrepl_section_regex ~r/<details by="fastrepl">.*?<\/details>/s

  defp fastrepl_section(content) do
    """
    <details by="fastrepl">
    <summary>For reviewers</summary>

    #{content}
    ---
    _Generated by [Fastrepl](https://github.com/fastrepl/fastrepl)_
    </details>
    """
    |> String.trim()
  end

  defp impl(%{
         "github_repo_full_name" => github_repo_full_name,
         "github_issue_number" => github_issue_number,
         "installation_id" => installation_id
       }) do
    [owner, repo] = String.split(github_repo_full_name, "/")

    with {:ok, token} <- Fastrepl.Github.get_installation_token(installation_id),
         {:ok, pr} <- get_pr(owner, repo, github_issue_number, token),
         {:ok, commits} <- get_commits(owner, repo, github_issue_number, token),
         {:ok, thought} <- understand_pr(pr, commits),
         {:ok, comment} <- write_comment(pr, commits, thought) do
      updated_pr_body =
        case Regex.run(@fastrepl_section_regex, pr.body) do
          nil -> pr.body <> "\n\n" <> comment
          [_] -> Regex.replace(@fastrepl_section_regex, pr.body, comment)
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
        {:ok, %{title: pr.title, body: Regex.replace(@fastrepl_section_regex, pr.body || "", "")}}

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

  defp write_comment(pr, commits, thought) do
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
            The user will provide you a information about the pull request. You should summarize the pull request and its changes, while respecting the initial thought.

            Your response should be valid, rich markdown that Github supports. Use backticks(``) for variable, filenames, package name, etc.

            Only use `### Description`, `#### Major Changes`, and OPTIONALLY `#### Minor Changes` sections.
            ``### Description` should be one-liner describing "What" the PR is about.
            `#### Major Changes` should be a list of descriptions of each main change. Each item in list should be very concise and short, and should not have child list.

            Ideally, there should be no `#### Minor Changes` section. But sometimes, PR contains some changes that are not related to the main purpose of the PR.
            If that change is not small enough to ignore, place it at `#### Major Changes` section.

            For both `#### Major Changes` and `#### Minor Changes`, try to merge multiple commits into one change if they are related.
            For example, if one commit create module calling OpenAI, and other commit change model name gpt-3.5-turbo to gpt-4, it should be merged into one change.

            At the high level, it should look like this:

            ### Description
            This PR ~

            #### Major Changes
            - Added ~

            #### Minor Changes
            - Modified ~
            """
          },
          %{
            role: "user",
            content: """
            Here's the information about the pull request:

            #{render_pr_with_commits(pr, commits)}

            This is initial thought about the pull request:
            #{thought}
            """
          }
        ]
      })

    case result do
      {:ok, content} -> {:ok, fastrepl_section(content)}
      {:error, error} -> {:error, error}
    end
  end

  def understand_pr(pr, commits) do
    Fastrepl.AI.chat(%{
      model: "gpt-4o",
      stream: false,
      temperature: 0.2,
      messages: [
        %{
          role: "system",
          content: """
          You are a senior software engineer with extensive experience in software development.

          When user provide you a information about the pull request, think step by step, and come up with the main points of the pull request.

          Keep in mind that although it is best practice to have single main change in a PR, often it contains lots of small, unrelated changes.'
          Your job is to identify only the core changes, and restate it in a concise sentences. With your input, I will later summarize the changes in the PR while classifying them into `Major Changes` and `Minor Changes`.

          For example, your response should look like this:

          Core changes are:
          - Updated config.ex for Oban
          - Added Oban worker in Fastrepl.PullRequest.Summary
          - Updated github webhook handler for pull_request event

          Unrelated changes are:
          - Added fallback in webhook handler
          - Updated CodeDiff.svelte
          """
        },
        %{
          role: "user",
          content: """
          Here's the information about the pull request:

          #{render_pr_with_commits(pr, commits)}
          """
        }
      ]
    })
  end

  defp render_pr_with_commits(pr, commits) do
    rendered = """
    <pr_title>
    #{pr.title}
    </pr_title>

    <pr_body>
    #{pr.body}
    </pr_body>
    """

    rendered =
      commits
      |> Enum.reduce(rendered, fn %{message: message, files: files}, acc ->
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

        acc <> "\n\n" <> commit_rendered
      end)

    rendered
  end
end
