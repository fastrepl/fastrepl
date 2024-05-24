defmodule Fastrepl.Renderer.Github do
  use Memoize

  alias Fastrepl.URL
  alias Fastrepl.Renderer
  alias Fastrepl.Github.Issue
  alias Fastrepl.Github.Repo

  def render_issue(%Issue{} = issue, opts \\ []) do
    opts = Keyword.merge([render_urls: true], opts)

    toplevel_tag = if issue.is_pr, do: "pr", else: "issue"
    title_prefix = if issue.is_pr, do: "PR ", else: "Issue "
    title_tag = if issue.is_pr, do: "pr_title", else: "issue_title"
    body_tag = if issue.is_pr, do: "pr_body", else: "issue_body"

    comments = issue.comments |> Enum.map(&render_issue_comment/1) |> Enum.join("\n\n")

    text = """
    <#{toplevel_tag}>
    <#{title_tag}>
    [#{title_prefix} ##{issue.number}]: #{issue.title}
    </#{title_tag}>
    <#{body_tag}>
    #{issue.body}
    </#{body_tag}>
    #{comments}
    </#{toplevel_tag}>
    """

    rendered =
      if !opts[:render_urls] do
        text
      else
        issue.body
        |> URL.from()
        |> Enum.reject(&String.contains?(&1, issue.url))
        |> Enum.reduce(text, &String.replace(&2, &1, Renderer.Github.render_url(&1)))
        |> String.trim()
      end

    String.trim(rendered)
  end

  defp render_issue_comment(%Issue.Comment{} = comment) do
    comments_tag = if comment.is_pr, do: "pr_comment", else: "issue_comment"

    text =
      """
      <#{comments_tag}>
      [#{comment.user_name}]: #{comment.body}
      </#{comments_tag}>
      """

    comment.body
    |> URL.from()
    |> Enum.reject(&String.contains?(&1, comment.issue_url))
    |> Enum.reduce(text, &String.replace(&2, &1, Renderer.Github.render_url(&1)))
    |> String.trim()
  end

  def render_url(url) do
    html = html_from_url(url)

    cond do
      github_repo_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/?$/, url) do
          [_, repo_full_name] ->
            get_readme_content(repo_full_name)

          _ ->
            ""
        end

      github_commit_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/commit\/(\w+)/, url) do
          [_, repo_full_name, hash] ->
            commit = get_commit_diff(repo_full_name, hash)

            diff =
              commit.files
              |> Enum.map(&"```#{&1.filename}\n#{&1.patch}\n```")
              |> Enum.join("\n\n")

            "\n" <> "#{commit.commit.message}\n\n#{diff}"

          _ ->
            ""
        end

      github_issue_or_pr_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/(?:issues|pull)\/(\d+)/, url) do
          [_, repo_full_name, issue_number] ->
            issue = Issue.from!(repo_full_name, String.to_integer(issue_number))
            "\n" <> Renderer.Github.render_issue(issue)

          _ ->
            ""
        end

      github_blob_url?(url) ->
        case Regex.run(
               ~r/github\.com\/([\w-]+\/[\w-]+)\/blob\/([0-9a-f]{40})\/([\w\/\.-]+)(?:#L(\d+)(?:-L(\d+))?)?/,
               url
             ) do
          [_, repo, ref, file_path] ->
            content = get_file_content(repo, file_path, ref)

            "\n" <>
              """
              ```#{file_path}
              #{content}
              ```
              """

          [_, repo, ref, file_path, line_start] ->
            content = get_file_content(repo, file_path, ref)

            selected =
              content
              |> String.split("\n")
              |> Enum.slice(String.to_integer(line_start) - 1, 1)
              |> Enum.join("\n")

            "\n" <>
              """
              ```#{file_path}#L#{line_start}
              #{selected}
              ```
              """

          [_, repo, ref, file_path, line_start, line_end] ->
            content = get_file_content(repo, file_path, ref)

            selected =
              content
              |> String.split("\n")
              |> Enum.slice(
                String.to_integer(line_start) - 1,
                String.to_integer(line_end) - String.to_integer(line_start) + 1
              )
              |> Enum.join("\n")

            """
            [#{url}]
            ```#{file_path}#L#{line_start}-#{line_end}
            #{selected}
            ```
            """

          _ ->
            ""
        end

      true ->
        try do
          case html |> Readability.article() |> Readability.readable_text() do
            "" -> "(#{url})"
            text -> text
          end
        rescue
          _ -> "(#{url})"
        end
    end
  end

  defp github_repo_url?(url) do
    case Regex.run(~r/github\.com\/[\w-]+\/[\w-]+\/?$/, url) do
      nil -> false
      _ -> true
    end
  end

  defp github_commit_url?(url) do
    case Regex.run(~r/github\.com\/[\w-]+\/[\w-]+\/commit\/[0-9a-f]{40}/, url) do
      nil -> false
      _ -> true
    end
  end

  defp github_issue_or_pr_url?(url) do
    case Regex.run(~r/github\.com\/[\w-]+\/[\w-]+\/(?:issues|pull)\/(\d+)/, url) do
      nil -> false
      _ -> true
    end
  end

  defp github_blob_url?(url) do
    case Regex.run(~r/github\.com\/[\w-]+\/[\w-]+\/blob\/[0-9a-f]{40}/, url) do
      nil -> false
      _ -> true
    end
  end

  defmemo html_from_url(url, timeout \\ 2_000) do
    res = Fastrepl.rest_client() |> Req.get(url: url, receive_timeout: timeout)

    case res do
      {:ok, %{body: body}} -> body
      _ -> ""
    end
  end

  defmemo get_commit_diff(repo_full_name, hash) do
    Repo.get_commit_diff(repo_full_name, hash)
  end

  defmemo get_file_content(repo_full_name, path, ref) do
    Repo.get_file_content(repo_full_name, path, ref)
  end

  defmemo get_readme_content(repo_full_name) do
    Repo.get_readme_content(repo_full_name)
  end
end
