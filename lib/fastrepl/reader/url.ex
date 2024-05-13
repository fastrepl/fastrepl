defmodule Fastrepl.Reader.URL do
  use Memoize

  alias Fastrepl.Github

  defmemo html_from_url(url, timeout \\ 2_000) do
    case Req.get(url: url, receive_timeout: timeout) do
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

  def text_from_url(url) do
    html = html_from_url(url)

    cond do
      github_repo_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/?$/, url) do
          [_, repo_full_name] ->
            article = html |> Floki.parse_document!() |> Floki.find("article")

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

            "#{commit.commit.message}\n\n#{diff}"

          _ ->
            ""
        end

      github_issue_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/issues\/(\d+)/, url) do
          [_, repo_full_name, issue_number] ->
            issue =
              get_issue(repo_full_name, issue_number)
              |> Fastrepl.LLM.render()

            comments =
              list_issue_comments(repo_full_name, issue_number)
              |> Enum.map(&Fastrepl.LLM.render/1)
              |> Enum.join("\n\n")

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
            pr = get_issue(repo_full_name, pr_number)

            comments =
              list_issue_comments(repo_full_name, pr_number)
              |> Enum.map(&Fastrepl.LLM.render/1)
              |> Enum.join("\n\n")

            """
            [PR ##{pr_number}] #{pr.title}\n\n#{pr.body}

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
          html
          |> Readability.article()
          |> Readability.readable_text()
        rescue
          _ -> ""
        end
    end
  end

  @spec urls_from_text(String.t()) :: [String.t()]
  def urls_from_text(text) do
    regex =
      ~r/(?:(?:https?|ftp|file):\/\/|www\.|ftp\.)(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#\/%=~_|$?!:,.])*(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[A-Z0-9+&@#\/%=~_|$])/i

    text
    |> then(&Regex.scan(regex, &1))
    |> List.flatten()
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn url -> url == "" end)
  end

  def github_repo_url?(url) do
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

  def github_blob_url?(url) do
    case Regex.run(~r/github\.com\/[\w-]+\/[\w-]+\/blob\/[0-9a-f]{40}/, url) do
      nil -> false
      _ -> true
    end
  end
end
