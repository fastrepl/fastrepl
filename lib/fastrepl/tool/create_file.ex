defmodule Fastrepl.Tool.CreateFile do
  @behaviour Fastrepl.Tool

  def run(
        %{
          "file_path" => _file_path,
          "file_name" => _file_name,
          "content" => _content
        },
        _context
      ) do
  end

  def as_function() do
    LangChain.Function.new!(%{
      name: "create_file",
      description: """
      Create a new code file in the specified location with the given file name and extension.
      This is useful when the task requires adding entirely new functionality or classes to the codebase.
      """,
      parameters_schema: %{
        type: "object",
        properties: %{
          file_path: %{
            type: "string",
            description: """
            The path where the new file will be created, relative to the root of the codebase.
            Do not include the file name itself. Use "file_name" parameter instead.
            """
          },
          file_name: %{
            type: "string",
            description: """
            The name of the file to create. This should be a valid file name, including the extension.
            Do not include the folder path. Use "file_path" parameter instead.
            """
          },
          content: %{
            type: "string",
            description:
              "The content of the file to create. This should be complete, valid code. Add commments if things are unclear."
          }
        },
        required: ["file_path", "file_name", "content"]
      },
      function: fn _args, _context -> :noop end
    })
  end
end
