defmodule Fastrepl.Retrieval.Tool.SemanticSearch do
  @behaviour Fastrepl.Retrieval.Tool

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Result

  def run(%{"query" => query}, %{chunks: chunks}) do
    Vectordb.query(query, chunks, top_k: 5, threshold: 0.3)
    |> Enum.map(&Result.from!(&1))
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
