defmodule Fastrepl.Retrieval.Tool.SemanticSearch do
  @behaviour Fastrepl.Retrieval.Tool
  use Tracing

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Result
  alias Fastrepl.Retrieval.Context

  @spec run(Context.t(), map()) :: [Result.t()]
  def run(%Context{} = ctx, %{"query" => query}) do
    Tracing.span %{}, "semantic_search" do
      results =
        Vectordb.query(query, ctx.chunks, top_k: 5, threshold: 0.3)
        |> Enum.map(&Result.from!(ctx.repo_root_path, &1))

      Tracing.set_attribute("query", query)
      Tracing.set_attribute("results_size", length(results))
      results
    end
  end

  def name() do
    "semantic_search"
  end

  def schema() do
    %{
      type: "function",
      function: %{
        name: name(),
        description: """
        use this function if you have description or similar code in mind that you want to retrieve.
        """,
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
