defmodule Fastrepl.Retrieval.Planner do
  use Retry

  alias LangChain.Chains.LLMChain
  alias LangChain.Message

  alias Fastrepl.Renderer

  @spec from_issue(
          [module()],
          GitHub.Issue.t(),
          [GitHub.Issue.Comment.t()]
        ) :: {[module()], [map()]}
  def from_issue(tools, issue, comments \\ []) do
    messages = [
      Message.new_system!(
        """
        You are a helpful code retrieval planner.
        """
        |> String.trim()
      ),
      Message.new_user!(
        """
        #{Renderer.Github.render_issue(issue)}
        #{comments |> Enum.map(&Renderer.Github.render_comment/1) |> Enum.join("\n")}
        ---

        Based on the issue above, use tools to retrieve code snippets that are useful to understand or solve the issue.
        Use as many tools as needed.
        """
        |> String.trim()
      )
    ]

    {tools, request(tools, messages)}
  end

  defp request(tools, messages) do
    tools = tools |> Enum.map(& &1.as_function())

    retry with:
            exponential_backoff()
            |> randomize
            |> cap(1_000)
            |> expiry(4_000) do
      LLMChain.new!(%{
        llm: Fastrepl.chat_model(%{model: "gpt-4o", stream: false, temperature: 0})
      })
      |> LLMChain.add_tools(tools)
      |> LLMChain.add_messages(messages)
      |> LLMChain.run()
    after
      {:ok, _, %Message{} = message} ->
        tool_calls =
          message.tool_calls
          |> Enum.map(fn %{name: name, arguments: arguments} -> {name, arguments} end)

        tool_calls
    else
      error -> []
    end
  end
end
