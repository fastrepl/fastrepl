defmodule Fastrepl.Renderer.Github do
  alias Fastrepl.Renderer
  alias Fastrepl.URL

  def render_pr(%{
        title: title,
        number: number,
        body: body,
        url: pr_url
      }) do
    text = """
    <pr>
    <pr_title>
    #PR ##{number}: #{title}
    </pr_title>
    <pr_body>
    #{body}
    </pr_body>
    </pr>
    """

    body
    |> URL.from()
    |> Enum.reject(&String.contains?(&1, pr_url))
    |> Enum.reduce(text, fn url, acc ->
      content = Renderer.URL.render(url)
      String.replace(acc, url, "```#{url}\n#{content}\n```")
    end)
    |> String.trim()
  end

  def render_issue(%{
        title: title,
        number: number,
        body: body,
        url: issue_url
      }) do
    text = """
    <issue>
    <issue_title>
    [Issue ##{number}]: #{title}
    </issue_title>
    <issue_body>
    #{body}
    </issue_body>
    <issue>
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

  def render_comment(%{
        body: body,
        issue_url: issue_url,
        user: %{login: name}
      }) do
    text =
      """
      <comment>
      [#{name}]: #{body}
      </comment>
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