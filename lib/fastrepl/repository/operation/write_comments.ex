defmodule Fastrepl.Repository.Operation.WriteComments do
  alias Fastrepl.Repository

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI, as: ChatModel
  alias LangChain.Message
  alias LangChain.Function

  @model_id "gpt-4-turbo-2024-04-09"

  @spec run(String.t(), Repository.File.t()) :: {:ok, [Repository.Comment.t()]} | {:error, any()}
  def run(goal, file) do
    {:ok, _, %Message{} = message} =
      LLMChain.new!(%{llm: ChatModel.new!(%{model: @model_id, stream: false, temperature: 0})})
      |> LLMChain.add_tools(tools())
      |> LLMChain.add_messages(messages(goal, file))
      |> LLMChain.run()

    if length(message.tool_calls) > 0 do
      comments =
        message.tool_calls
        |> Enum.map(&tool_call_to_comment(&1, file))
        |> Enum.filter(fn comment -> comment != nil end)

      {:ok, comments}
    else
      {:error, message}
    end
  end

  defp tool_call_to_comment(tool_call, file) do
    case tool_call.name do
      "write_instruction" ->
        %Repository.Comment{
          file_path: file.path,
          line_start: Repository.File.find_line(file.path, tool_call.arguments["block_start"]),
          line_end: Repository.File.find_line(file.path, tool_call.arguments["block_end"]),
          content: tool_call.arguments["instruction"]
        }

      "mark_as_readonly" ->
        %Repository.Comment{
          file_path: file.path,
          line_start: Repository.File.find_line(file.path, tool_call.arguments["block_start"]),
          line_end: Repository.File.find_line(file.path, tool_call.arguments["block_end"]),
          content: tool_call.arguments["comment"]
        }

      _ ->
        nil
    end
  end

  defp messages(goal, file) do
    [
      Message.new_system!("""
      You are senior software engineer with wide experience in guiding and mentoring developers.
      """),
      Message.new_user!("""
      This is my goal:
      ---
      #{goal}
      ---

      This is the file:
      ---
      ```#{file.path}
      #{file.content}
      ```
      ---

      Use the given tools to help me achieve the goal in the file.
      If you think the given file is not relevant to the goal, DON"T EXPLAIN ANYTHING, JUST RETURN "NONE".
      """)
    ]
  end

  defp tools() do
    [
      Function.new!(%{
        name: "mark_as_readonly",
        description: """
        Mark a single block of code as read-only. The block should be valid chunk of code.
        Use this function if there's nothing to touch in the file, but you still think it's relevant to the goal. Call this function multiple times to mark multiple blocks as read-only.
        Read-only files will not be modified to achieve the goal, but they will be used as a reference. Use "comment" parameter to explain how this can be useful as a reference.
        """,
        parameters_schema: %{
          type: "object",
          properties: %{
            "block_start" => %{
              type: "string",
              description: """
              First few lines of a single block to mark as read-only. At least two lines to avoid ambiguity.
              This should be copied as-is including the whitespace.
              """
            },
            "block_end" => %{
              type: "string",
              description: """
              Last few lines of a single block to mark as read-only. At least two lines to avoid ambiguity.
              This should be copied as-is including the whitespace.
              """
            },
            "comment" => %{
              type: "string",
              description: """
              A comment explaining how this file can be useful as a reference.
              The comment should be very specific to the goal.
              """
            }
          },
          required: ["block_start", "block_end", "comment"]
        },
        function: fn _args, _context -> :noop end
      }),
      Function.new!(%{
        name: "write_instruction",
        description: """
        Based on the given context, write a comment on a single block of code. The block should be valid chunk of code.
        Use this function when there's specific operation needed to be done on the block in order to achieve the goal. Call this function multiple times to write multiple instructions.
        """,
        parameters_schema: %{
          type: "object",
          properties: %{
            "block_start" => %{
              type: "string",
              description: """
              First few lines of a single block to write a comment on. At least two lines to avoid ambiguity.
              This should be copied as-is including the whitespace.
              """
            },
            "block_end" => %{
              type: "string",
              description: """
              Last few lines of a single block to write a comment on. At least two lines to avoid ambiguity.
              This should be copied as-is including the whitespace.
              """
            },
            "instruction" => %{
              type: "string",
              description: """
              Detailed, self-contained, step-by-step instructions on what changes need to be made, and how to do it.
              """
            }
          },
          required: ["block_start", "block_end", "instruction"]
        },
        function: fn _args, _context -> :noop end
      })
    ]
  end
end
