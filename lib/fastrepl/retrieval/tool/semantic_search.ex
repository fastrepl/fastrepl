defmodule Fastrepl.Retrieval.Tool.SemanticSearch do
  @behaviour Fastrepl.Retrieval.Tool

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Result
  alias Fastrepl.Retrieval.Context

  @spec run(Context.t(), map()) :: [Result.t()]
  def run(%Context{} = ctx, %{"query" => query}) do
    Vectordb.query(query, ctx.chunks, top_k: 5, threshold: 0.3)
    |> Enum.map(&Result.from!(&1))
  end

  def name() do
    "semantic_search"
  end

  def schema() do
    %{
      type: "function",
      function: %{
        name: name(),
        description:
          """
          use this function if you have description or similar code in mind that you want to retrieve.
          """
          |> String.trim(),
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
