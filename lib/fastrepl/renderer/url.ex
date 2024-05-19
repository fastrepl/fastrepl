defmodule Fastrepl.Renderer.URL do
  use Memoize

  alias Fastrepl.Renderer
  alias Fastrepl.Github

  defmemo html_from_url(url, timeout \\ 2_000) do
    res = Fastrepl.req_client() |> Req.get(url: url, receive_timeout: timeout)

    case res do
      {:ok, %{body: body}} -> body
      _ -> ""
    end
  end

  defmemo get_commit(repo_full_name, hash) do
    Github.get_commit!(repo_full_name, hash)
  end

  defmemo get_issue(repo_full_name, issue_number) do
    Github.get_issue!(repo_full_name, String.to_integer(issue_number))
  end

  defmemo list_issue_comments(repo_full_name, issue_number) do
    Github.list_issue_comments!(repo_full_name, String.to_integer(issue_number))
  end

  defmemo get_content(repo_full_name, path, ref) do
    %{content: content} = Github.get_content!(repo_full_name, path, ref)

    content
    |> String.split("\n")
    |> Enum.map(&Base.decode64!/1)
    |> Enum.join("")
  end

  def render(url) do
    html = html_from_url(url)

    cond do
      github_repo_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/?$/, url) do
          [_, repo_full_name] ->
            article = html |> Floki.parse_document!() |> Floki.find("article")

            "\n" <>
              """
              [#{repo_full_name}]

              ```README
              #{Floki.text(article)}
              ```
              """

          _ ->
            ""
        end

      github_commit_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/commit\/(\w+)/, url) do
          [_, repo_full_name, hash] ->
            commit = get_commit(repo_full_name, hash)

            diff =
              commit.files
              |> Enum.map(&"```#{&1.filename}\n#{&1.patch}\n```")
              |> Enum.join("\n\n")

            "\n" <> "#{commit.commit.message}\n\n#{diff}"

          _ ->
            ""
        end

      github_issue_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/issues\/(\d+)/, url) do
          [_, repo_full_name, issue_number] ->
            issue =
              get_issue(repo_full_name, issue_number)
              |> Renderer.Github.render_issue()

            comments =
              list_issue_comments(repo_full_name, issue_number)
              |> Enum.filter(&(&1.performed_via_github_app == nil))
              |> Enum.map(&Renderer.Github.render_comment/1)
              |> Enum.join("\n\n")

            "\n" <>
              """
              #{issue}

              #{comments}
              """

          _ ->
            ""
        end

      github_pr_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/pull\/(\d+)/, url) do
          [_, repo_full_name, pr_number] ->
            pr =
              get_issue(repo_full_name, pr_number)
              |> Renderer.Github.render_pr()

            comments =
              list_issue_comments(repo_full_name, pr_number)
              |> Enum.filter(&(&1.performed_via_github_app == nil))
              |> Enum.map(&Renderer.Github.render_comment/1)
              |> Enum.join("\n\n")

            "\n" <>
              """
              #{pr}

              #{comments}
              """

          _ ->
            ""
        end

      github_blob_url?(url) ->
        case Regex.run(
               ~r/github\.com\/([\w-]+\/[\w-]+)\/blob\/([0-9a-f]{40})\/([\w\/\.-]+)(?:#L(\d+)(?:-L(\d+))?)?/,
               url
             ) do
          [_, repo, ref, file_path] ->
            content = get_content(repo, file_path, ref)

            "\n" <>
              """
              ```#{file_path}
              #{content}
              ```
              """

          [_, repo, ref, file_path, line_start] ->
            content = get_content(repo, file_path, ref)

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
            content = get_content(repo, file_path, ref)

            selected =
              content
              |> String.split("\n")
              |> Enum.slice(
                String.to_integer(line_start) - 1,
                String.to_integer(line_end) - String.to_integer(line_start) + 1
              )
              |> Enum.join("\n")

            "\n" <>
              """
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

  defp github_issue_url?(url) do
    case Regex.run(~r/github\.com\/[\w-]+\/[\w-]+\/issues\/\d+/, url) do
      nil -> false
      _ -> true
    end
  end

  defp github_pr_url?(url) do
    case Regex.run(~r/github\.com\/[\w-]+\/[\w-]+\/pull\/\d+/, url) do
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
end
