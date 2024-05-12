defmodule Fastrepl.Reader.URL do
  use Memoize

  alias Fastrepl.Github

  defmemo html_from_url(url, timeout \\ 2_000) do
    case Req.get(url: url, receive_timeout: timeout) do
      {:ok, %{body: body}} -> body
      _ -> ""
    end
  end

  defmemo get_commit(repo, hash) do
    Github.get_commit!(repo, hash)
  end

  def text_from_html(url) do
    html = html_from_url(url)

    cond do
      is_github_commit_url?(url) ->
        case Regex.run(~r/([^\/]+\/[^\/]+)\/commit\/(\w+)/, url) do
          [_, repo, hash] ->
            commit = get_commit(repo, hash)

            diff =
              commit.files
              |> Enum.map(&"```#{&1.filename}\n#{&1.patch}\n```")
              |> Enum.join("\n\n")

            "#{commit.commit.message}\n\n#{diff}"

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

  def is_github_commit_url?(url) do
    case Regex.run(~r/github\.com\/[\w-]+\/[\w-]+\/commit\/[0-9a-f]{40}/, url) do
      nil -> false
      _ -> true
    end
  end
end
