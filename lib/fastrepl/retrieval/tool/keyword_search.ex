defmodule Fastrepl.Retrieval.Tool.KeywordSearch do
  @behaviour Fastrepl.Retrieval.Tool

  alias Fastrepl.FS
  alias Fastrepl.Retrieval.Grep
  alias Fastrepl.Retrieval.Result

  def run(%{"query" => query}, %{root_path: root_path}) do
    root_path
    |> FS.list_informative_files()
    |> Enum.map(fn path ->
      lines = path |> Grep.grep_file(query)

      if Enum.empty?(lines),
        do: nil,
        else: Result.from!(path, lines)
    end)
    |> Enum.reject(&is_nil/1)
  end

  def as_function() do
    LangChain.Function.new!(%{
      name: "keyword_search",
      function: fn _args, _context -> :noop end,
      parameters_schema: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description:
              "This is not filename or path, but keyword or valid ripgrep regex that might be included in the code snippets."
          }
        },
        required: ["query"]
      }
    })
  end
end
