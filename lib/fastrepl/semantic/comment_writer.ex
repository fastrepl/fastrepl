defmodule Fastrepl.SemanticFunction.CommentWriter do
  alias Fastrepl.Renderer
  alias Fastrepl.Retrieval.Result
  alias Fastrepl.Retrieval.CodeBlock
  alias Fastrepl.Sessions.Comment
  alias Fastrepl.Github.Issue

  @spec run([Result.t()], Issue.t()) :: [Comment.t()]
  def run(results, issue) do
    goal = """
    This is Github issue that need to be handled:

    #{Renderer.Github.render_issue(issue)}
    """

    snippets =
      results
      |> Enum.map(&to_string/1)
      |> Enum.join("\n\n")

    result =
      Fastrepl.AI.chat(
        %{
          model: "gpt-4o",
          stream: false,
          temperature: 0,
          messages: messages(goal, snippets),
          tools: [modify_tool_schema()],
          tool_choice: "auto"
        },
        otel_attrs: %{module: __MODULE__}
      )

    case result do
      {:ok, comments} ->
        comments |> Enum.map(&to_comment(results, &1)) |> Enum.reject(&is_nil/1)

      {:error, _} ->
        []
    end
  end

  defp to_comment(results, tool_call) do
    %{name: name, args: args} = tool_call

    if name == modify_tool_name() do
      with result when not is_nil(result) <-
             Enum.find(results, &(&1.file_path == args["target_filepath"])),
           span when not is_nil(span) <-
             CodeBlock.find(args["target_section"], result.file_content) do
        %Comment{
          file_path: args["target_filepath"],
          line_start: elem(span, 0),
          line_end: elem(span, 1),
          content: args["comment_content"]
        }
      else
        _ -> nil
      end
    else
      nil
    end
  end

  defp messages(goal, snippets) do
    [
      %{
        role: "system",
        content: """
        You are senior software engineer with wide experience in guiding and mentoring developers.

        The user will provide you with a file, and a goal to achieve.(for example, simple instructions or Github issue)
        You should think step by step and respond with comments. This can be one, multiple, or none.

        """
      },
      %{
        role: "user",
        content: """
        This is my goal:
        ---
        #{goal}
        ---

        This is the list of files:
        ---
        #{snippets}
        ---
        """
      }
    ]
  end

  defp modify_tool_name() do
    "write_modification_comment"
  end

  defp modify_tool_schema() do
    %{
      type: "function",
      function: %{
        name: modify_tool_name(),
        description: """
        Use this function when you want to modify a section of from the give file.
        Each modification should be focused on a single section of the file.
        """,
        parameters: %{
          type: "object",
          properties: %{
            target_filepath: %{
              type: "string",
              description: """
              The path of the target that you want to write comment to.
              Copy the path as-is, without any modification.
              """
            },
            target_section: %{
              type: "string",
              description: """
              The section of the target file that you want to write comment to.
              Copy the section as-is, without any modification.

              If the section you are targeting is too long(more than 30 lines), you can omit the middle part of the section like this:

              function hello() {
                const a = 1;
                ...
                const b = 2;
                return a + b;
              }
              """
            },
            comment_content: %{
              type: "string",
              description: """
              The comment should be really focused and concise.
              This should be self-contained, meaning that it should be possible to make the actual modification with the given comment.
              """
            }
          },
          required: ["target_filepath", "target_section", "comment_content"]
        }
      }
    }
  end
end
