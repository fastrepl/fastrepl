defmodule Fastrepl.SemanticFunction.PPWriter do
  def run(patches) do
    messages = [
      %{
        role: "user",
        content: """
        Here's the modifications that I made to the codebase:

        <patch>
        #{patches |> Enum.map(& &1.content) |> Enum.join("\n")}```
        </patch>

        Based on the information above, write a Pull request like a professional developer.
        """
      }
    ]

    result =
      Fastrepl.AI.chat(
        %{
          model: "gpt-3.5-turbo",
          stream: false,
          temperature: 0,
          messages: messages,
          tools: [tool_schema()]
        },
        otel_attrs: %{module: __MODULE__}
      )

    case result do
      {:ok, [%{args: %{"title" => title}}]} -> {:ok, title}
      {:ok, _} -> run(patches)
      _ -> {:error, "error"}
    end
  end

  defp tool_schema() do
    %{
      type: "function",
      function: %{
        name: "write_pull_request",
        parameters: %{
          type: "object",
          properties: %{
            title: %{
              type: "string",
              description: """
              Title of the Pull request. This should be self-explanatory, and clear about what is being changed.

              Here are some examples:

              - Add test case for getEventTarget
              - Improve cryptic error message when creating a component starting with a lowercase letter
              """
            }
          },
          required: ["title"]
        }
      }
    }
  end
end
