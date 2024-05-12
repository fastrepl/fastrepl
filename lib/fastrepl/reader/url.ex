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

  def text_from_html(url) do
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
            issue = get_issue(repo_full_name, issue_number)
            comments = list_issue_comments(repo_full_name, issue_number)

            """
            [Issue ##{issue_number}] #{issue.title}\n\n#{issue.body}

            #{comments |> Enum.map(&Fastrepl.LLM.render/1) |> Enum.join("\n\n")}
            """

          _ ->
            ""
        end

      github_pr_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/pull\/(\d+)/, url) do
          [_, repo_full_name, pr_number] ->
            pr = get_issue(repo_full_name, pr_number)
            comments = list_issue_comments(repo_full_name, pr_number)

            """
            [PR ##{pr_number}] #{pr.title}\n\n#{pr.body}

            #{comments |> Enum.map(&Fastrepl.LLM.render/1) |> Enum.join("\n\n")}
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
end
