defprotocol Fastrepl.LLM do
  def render(data)
end

defimpl Fastrepl.LLM, for: String do
  def render(data), do: data
end

defimpl Fastrepl.LLM, for: GitHub.Issue do
  alias Fastrepl.Renderer
  alias Fastrepl.URL

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
    |> URL.from()
    |> Enum.reject(&String.contains?(&1, issue_url))
    |> Enum.reduce(text, fn url, acc ->
      content = Renderer.URL.render(url)
      String.replace(acc, url, "```#{url}\n#{content}\n```")
    end)
    |> String.trim()
  end
end

defimpl Fastrepl.LLM, for: GitHub.Issue.Comment do
  alias Fastrepl.Renderer
  alias Fastrepl.URL

  def render(%{
        body: body,
        issue_url: issue_url,
        user: %{login: name}
      }) do
    text =
      """
      [#{name}]: #{body}
      """

    body
    |> URL.from()
    |> Enum.reject(&String.contains?(&1, issue_url))
    |> Enum.reduce(text, fn url, acc ->
      content = Renderer.URL.render(url)
      String.replace(acc, url, "```#{url}\n#{content}\n```")
    end)
    |> String.trim()
  end
end
