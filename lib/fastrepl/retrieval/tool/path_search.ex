defmodule Fastrepl.Retrieval.Tool.PathSearch do
  @behaviour Fastrepl.Retrieval.Tool

  alias Fastrepl.FS
  alias Fastrepl.Retrieval.Result

  def run(%{"query" => query}, %{root_path: root_path}) do
    root_path
    |> FS.search_paths(query)
    |> Enum.map(&Result.from!(&1))
  end

  def as_function() do
    LangChain.Function.new!(%{
      name: "path_search",
      description: """
      Use this function if you have file path in mind, or it is mentioned in the context.
      """,
      function: fn _args, _context -> :noop end,
      parameters_schema: %{
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
    })
  end
end
