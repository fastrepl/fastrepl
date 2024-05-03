defmodule Fastrepl.Tool.SemanticSearch do
  @behaviour Fastrepl.Tool

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Chunker.Chunk

  def run(%{"query" => query}, %{vectordb_pid: vectordb_pid, root_path: root_path}) do
    Vectordb.query(vectordb_pid, query, top_k: 5, threshold: 0.3)
    |> Enum.map(&%Chunk{&1 | file_path: Path.relative_to(&1.file_path, root_path)})
  end

  def as_function() do
    LangChain.Function.new!(%{
      name: "semantic_search",
      function: fn _args, _context -> :noop end,
      parameters_schema: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "Description about the code snippets to retrieve."
          }
        },
        required: ["query"]
      }
    })
  end
end
