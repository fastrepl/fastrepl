defmodule Fastrepl.Retrieval.Tool.PathSearch do
  @behaviour Fastrepl.Retrieval.Tool
  use Tracing

  alias Fastrepl.FS
  alias Fastrepl.Retrieval.Result
  alias Fastrepl.Retrieval.Context

  @spec run(Context.t(), map()) :: [Result.t()]
  def run(%Context{} = ctx, %{"query" => query}) do
    Tracing.span %{}, "path_search" do
      results =
        ctx.repo_root_path
        |> FS.search_paths(query)
        |> Enum.map(&Result.from!(&1))

      Tracing.set_attribute("query", query)
      Tracing.set_attribute("results_size", length(results))
      results
    end
  end

  def name() do
    "path_search"
  end

  def schema() do
    %{
      type: "function",
      function: %{
        name: name(),
        description:
          """
          Use this function if you have file path in mind, or it is mentioned in the context.
          """
          |> String.trim(),
        parameters: %{
          type: "object",
          properties: %{
            query: %{
              type: "string",
              description:
                """
                Exact filename, path, or partial keyword that might be included in the file path.
                """
                |> String.trim()
            }
          },
          required: ["query"]
        }
      }
    }
  end
end
