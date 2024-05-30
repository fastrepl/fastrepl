defmodule Fastrepl.SemanticFunction.IssueUnderstanding do
  @spec run(String.t()) :: {:ok, map()} | {:error, any()}
  def run(rendered) do
    messages = [
      %{
        role: "system",
        content: """
        You are a senior software engineer with extensive experience in resolving issues in open source projects.
        """
      },
      %{
        role: "user",
        content: """
        Here's the Github issue and comments. (This is scraped and parsed from the webpage.)
        #{rendered}

        Please help me handle this.
        """
      }
    ]

    llm(messages)
  end

  defp llm(messages) do
    result =
      Fastrepl.AI.chat(
        %{
          model: "gpt-3.5-turbo",
          messages: messages,
          tools: [summarize_tool_schema()],
          tool_choice: "auto"
        },
        otel_attrs: %{module: __MODULE__}
      )

    case result do
      {:ok, [%{args: %{"summary" => summary, "files" => files}}]} ->
        {:ok, %{summary: summary, files: files}}

      other ->
        other
    end
  end

  defp summarize_tool_schema() do
    %{
      type: "function",
      function: %{
        name: "summarize_issue",
        description: """
        Summarize the Github issue and comments in markdown format.
        The summary should be straightforward, so that anyone can start working on the issue.
        """,
        parameters: %{
          type: "object",
          properties: %{
            summary: %{
              type: "string",
              description: """
              A concise summary of the Github issue and comments.
              """
            },
            files: %{
              type: "array",
              description: """
              Every single file mentioned in the issue. This can be complete or partial parth.
              """,
              items: %{type: "string"}
            }
          },
          required: ["summary", "files"]
        }
      }
    }
  end
end
