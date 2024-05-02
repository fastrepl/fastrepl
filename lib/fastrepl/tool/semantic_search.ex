defmodule Fastrepl.Tool.SemanticSearch do
  @behaviour Fastrepl.Tool

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Chunker.Chunk

  def run(%{"query" => query}, %{vectordb_pid: vectordb_pid, root_path: root_path}) do
    Vectordb.query(vectordb_pid, query, top_k: 5, threshold: 0.3)
    |> Enum.map(&%Chunk{&1 | file_path: Path.relative_to(&1.file_path, root_path)})
  end

  def openai_tool_format() do
    %{
      type: "function",
      function: %{
        name: "semantic_search",
        description: "use embedding and cosine similarity to find relevant code snippets",
        parameters: %{
          type: "object",
          properties: %{
            query: %{
              type: "string",
              description: "Description about the code snippets to retrieve."
            }
          },
          required: ["query"]
        }
      }
    }
  end
end
