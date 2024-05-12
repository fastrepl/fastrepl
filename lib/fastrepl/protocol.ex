defprotocol Fastrepl.LLM do
  def render(data)
end

defimpl Fastrepl.LLM, for: String do
  def render(data), do: data
end

defimpl Fastrepl.LLM, for: GitHub.Issue do
  alias Fastrepl.Reader

  def render(%{
        title: title,
        number: number,
        body: body,
        url: issue_url
      }) do
    text = """
    ##{number}: #{title}
    ---
    #{body}
    """

    body
    |> Reader.URL.urls_from_text()
    |> Enum.reject(&String.contains?(&1, issue_url))
    |> Enum.reduce(text, fn url, acc ->
      content = Reader.URL.text_from_html(url)
      String.replace(acc, url, "```#{url}\n#{content}\n```")
    end)
    |> String.trim()
  end
end

defimpl Fastrepl.LLM, for: GitHub.Issue.Comment do
  alias Fastrepl.Reader

  def render(%{
        body: body,
        issue_url: issue_url,
        user: %{name: name}
      }) do
    text =
      """
      #{name}:
      #{body}
      """

    body
    |> Reader.URL.urls_from_text()
    |> Enum.reject(&String.contains?(&1, issue_url))
    |> Enum.reduce(text, fn url, acc ->
      content = Reader.URL.text_from_html(url)
      String.replace(acc, url, "```#{url}\n#{content}\n```")
    end)
    |> String.trim()
  end
end
