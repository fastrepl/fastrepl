defmodule Fastrepl.Retrieval.Tool.SemanticSearch do
  @behaviour Fastrepl.Retrieval.Tool

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Chunker.Chunk

  def run(%{"query" => query}, %{root_path: root_path, chunks: chunks}) do
    Vectordb.query(query, chunks, top_k: 5, threshold: 0.3)
    |> Enum.map(&%Chunk{&1 | file_path: Path.relative_to(&1.file_path, root_path)})
  end

  def as_function() do
    LangChain.Function.new!(%{
      name: "semantic_search",
      description: """
      use this function if you have description or similar code in mind that you want to retrieve.
      """,
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