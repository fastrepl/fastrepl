defmodule Fastrepl.Retrieval.Planner do
  @model_id "gpt-4-turbo-2024-04-09"

  use Retry

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI, as: ChatModel
  alias LangChain.Message

  alias Fastrepl.Tool.KeywordSearch
  alias Fastrepl.Tool.SemanticSearch
  alias Fastrepl.Tool.PathSearch

  alias Fastrepl.Renderer

  def from_query(chat) do
    messages = [
      Message.new_system!(
        """
        You are a helpful code retrieval planner.
        Based on the user's query and context, use tools to retrieve relevant code snippets.
        Use as many tools as needed.
        """
        |> String.trim()
      ),
      Message.new_user!(chat |> String.trim())
    ]

    request(messages)
  end

  @spec from_issue(GitHub.Issue.t(), [GitHub.Issue.Comment.t()]) :: {:ok, [{String.t(), map()}]}
  def from_issue(issue, comments \\ []) do
    messages = [
      Message.new_system!(
        """
        You are a helpful code retrieval planner.
        """
        |> String.trim()
      ),
      Message.new_user!(
        """
        [Github issue]

        #{Renderer.Github.render_issue(issue)}
        ---

        #{comments |> Enum.map(&Renderer.Github.render_comment/1) |> Enum.join("\n")}
        ---

        Based on the issue above, use tools to retrieve code snippets that are useful to understand or solve the issue.
        Use as many tools as needed.
        """
        |> String.trim()
      )
    ]

    request(messages)
  end

  defp request(messages) do
    tools = [
      KeywordSearch.as_function(),
      SemanticSearch.as_function(),
      PathSearch.as_function()
    ]

    retry with:
            exponential_backoff()
            |> randomize
            |> cap(1_000)
            |> expiry(4_000) do
      LLMChain.new!(%{llm: ChatModel.new!(%{model: @model_id, stream: false, temperature: 0})})
      |> LLMChain.add_tools(tools)
      |> LLMChain.add_messages(messages)
      |> LLMChain.run()
    after
      {:ok, _, %Message{} = message} ->
        tool_calls =
          message.tool_calls
          |> Enum.map(fn %{name: name, arguments: arguments} -> {name, arguments} end)

        {:ok, tool_calls}
    else
      error -> []
    end
  end
end
