defmodule Fastrepl.Tool.PathSearch do
  @behaviour Fastrepl.Tool

  alias Fastrepl.FS
  alias Fastrepl.Retrieval.Chunker.Chunk

  def run(%{"query" => query}, %{root_path: root_path}) do
    root_path
    |> FS.search_paths(query)
    |> Enum.map(&Chunk.from(root_path, &1))
  end

  def openai_tool_format() do
    %{
      type: "function",
      function: %{
        name: "path_search",
        description: "search files with path",
        parameters: %{
          type: "object",
          properties: %{
            query: %{
              type: "string",
              description:
                "Exact filename, path, or partial keyword that might be included in the file path."
            }
          },
          required: ["query"]
        }
      }
    }
  end
end
