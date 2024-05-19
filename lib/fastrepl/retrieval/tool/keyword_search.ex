defmodule Fastrepl.Retrieval.Tool.KeywordSearch do
  @behaviour Fastrepl.Retrieval.Tool

  alias Fastrepl.FS
  alias Fastrepl.Native.CodeUtils
  alias Fastrepl.Retrieval.Result

  def run(%{"query" => query}, %{root_path: root_path}) do
    root_path
    |> FS.list_informative_files()
    |> Enum.map(fn path ->
      lines = CodeUtils.grep_file(path, query)

      if Enum.empty?(lines),
        do: nil,
        else: Result.from!(path, lines)
    end)
    |> Enum.reject(&is_nil/1)
  end

  def schema() do
    %{
      type: "function",
      function: %{
        name: "keyword_search",
        parameters: %{
          type: "object",
          properties: %{
            query: %{
              type: "string",
              description:
                """
                This is not filename or path, but keyword or valid ripgrep regex that might be included in the code snippets.
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
