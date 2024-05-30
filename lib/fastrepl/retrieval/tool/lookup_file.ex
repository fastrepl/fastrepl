defmodule Fastrepl.Retrieval.Tool.LookupFile do
  @behaviour Fastrepl.Retrieval.Tool
  use Tracing

  alias Fastrepl.Retrieval.Context
  alias Fastrepl.Retrieval.Result

  @spec run(Context.t(), map()) :: [Result.t()]
  def run(%Context{repo_root_path: root_path}, %{"path" => path}) do
    Tracing.span %{}, name() do
      [
        Result.from!(root_path, path)
      ]
    end
  end

  def name(), do: "lookup_file"

  def schema() do
    %{
      type: "function",
      function: %{
        name: name(),
        description: """
        Use this function if you want to directly open a file in the codebase.
        """,
        parameters: %{
          type: "object",
          properties: %{
            path: %{
              type: "string",
              description: """
              Exact filename that is mentioned in the context.
              """
            }
          },
          required: ["path"]
        }
      }
    }
  end
end
