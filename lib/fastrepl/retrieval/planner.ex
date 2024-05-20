defmodule Fastrepl.Retrieval.Planner do
  alias Fastrepl.Renderer
  alias Fastrepl.Retrieval.Context

  @spec run(Context.t(), GitHub.Issue.t(), [GitHub.Issue.Comment.t()]) :: {Context.t(), [map()]}
  def run(%Context{} = ctx, issue, comments) do
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

    result = request(ctx.tools, messages)
    {ctx, result}
  end

  defp request(tools, messages) do
    res =
      Fastrepl.AI.chat(%{
        model: "gpt-4-turbo",
        messages: messages,
        tools: Enum.map(tools, & &1.schema())
      })

    case res do
      {:ok, tool_calls} -> tool_calls
      {:error, _} -> []
    end
  end
end
