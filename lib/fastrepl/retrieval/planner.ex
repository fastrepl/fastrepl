defmodule Fastrepl.Retrieval.Planner do
  alias Fastrepl.Renderer

  @spec from_issue(
          [module()],
          GitHub.Issue.t(),
          [GitHub.Issue.Comment.t()]
        ) :: {[module()], [map()]}
  def from_issue(tools, issue, comments \\ []) do
    messages = [
      %{
        role: "system",
        content:
          """
          You are a helpful code retrieval planner.
          """
          |> String.trim()
      },
      %{
        role: "user",
        content: """
        #{Renderer.Github.render_issue(issue)}
        #{comments |> Enum.map(&Renderer.Github.render_comment/1) |> Enum.join("\n")}
        ---

        Based on the issue above, use tools to retrieve code snippets that are useful to understand or solve the issue.
        Use as many tools as needed.
        """
      }
    ]

    case request(tools, messages) do
      {:ok, tool_calls} ->
        {tools, tool_calls}

      {:error, _} ->
        {tools, []}
    end
  end

  defp request(tools, messages) do
    Fastrepl.AI.chat(%{
      model: "gpt-4-turbo",
      messages: messages,
      tools: Enum.map(tools, & &1.schema())
    })
  end
end
