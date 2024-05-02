defmodule Fastrepl.Tool.KeywordSearch do
  @behaviour Fastrepl.Tool

  alias Fastrepl.FS
  alias Fastrepl.Retrieval.Grep
  alias Fastrepl.Retrieval.Chunker.Chunk

  def run(%{"query" => query}, %{root_path: root_path}) do
    root_path
    |> FS.list_informative_files()
    |> Enum.map(fn path ->
      lines = path |> Grep.grep_file(query)

      if Enum.empty?(lines),
        do: nil,
        else: Chunk.from(root_path, path, lines)
    end)
    |> Enum.reject(&is_nil/1)
  end

  def openai_tool_format() do
    %{
      type: "function",
      function: %{
        name: "keyword_search",
        description: "use grep to find relevant code snippets",
        parameters: %{
          type: "object",
          properties: %{
            query: %{
              type: "string",
              description:
                "This is not filename or path, but keyword or valid ripgrep regex that might be included in the code snippets."
            }
          },
          required: ["query"]
        }
      }
    }
  end
end
