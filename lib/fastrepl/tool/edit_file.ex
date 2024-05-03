defmodule Fastrepl.Tool.EditFile do
  @behaviour Fastrepl.Tool

  def run(
        %{
          "file_path" => _file_path,
          "original_code" => _original_code,
          "new_code" => _new_code
        },
        _context
      ) do
  end

  def as_function() do
    LangChain.Function.new!(%{
      name: "edit_file",
      description: """
      Use this tool to make a single change to a single file in the codebase.
      If multiple parts of the file need to be changed, use this tool multiple times.
      """,
      parameters_schema: %{
        type: "object",
        properties: %{
          file_path: %{
            type: "string",
            description: """
            The name of the file to make changes to. This should be unmodified, full path including extension.
            """
          },
          original_code: %{
            type: "string",
            description: """
            The single, contiguous block of code that contains the part to be edited.
            This should be copied as-is from the original file.
            """
          },
          new_code: %{
            type: "string",
            description: """
            The new code to replace the original code with. This should be valid code with styles and formatting preserved.
            """
          }
        },
        required: ["file_path", "original_code", "new_code"]
      },
      function: fn _args, _context -> :noop end
    })
  end
end
