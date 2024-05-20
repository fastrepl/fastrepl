defmodule Fastrepl.Retrieval.Tool.KeywordSearch do
  @behaviour Fastrepl.Retrieval.Tool
  use Tracing

  alias Fastrepl.FS
  alias Fastrepl.Retrieval.Context
  alias Fastrepl.Native.CodeUtils
  alias Fastrepl.Retrieval.Result

  @spec run(Context.t(), map()) :: [Result.t()]
  def run(%Context{repo_root_path: root_path}, %{"query" => query}) do
    Tracing.span %{}, "keyword_search" do
      results =
        root_path
        |> FS.list_informative_files()
        |> Enum.map(fn path ->
          lines = CodeUtils.grep_file(path, query)

          if Enum.empty?(lines),
            do: nil,
            else: Result.from!(path, lines)
        end)
        |> Enum.reject(&is_nil/1)

      Tracing.set_attribute("query", query)
      Tracing.set_attribute("results_size", length(results))
      results
    end
  end

  def name() do
    "keyword_search"
  end

  def schema() do
    %{
      type: "function",
      function: %{
        name: name(),
        description:
          """
          Use this function if:
          1. you have some keywords in mind, or it is directly mentioned in the context.
          2. you want to find specific variables, functions, or classes in the codebase.

          Note that this is doing line-oriented literal matching, not multi-line or full-text search.
          """
          |> String.trim(),
        parameters: %{
          type: "object",
          properties: %{
            query: %{
              type: "string",
              description:
                """
                This is not filename or path, but keyword that might be included in the file content.
                You can use some tricks to make it more specific, such as:

                1. Use language specific keyword to find the function. For example, rather than searching for hello, you can search for `def hello(`.
                2. Similar to the above, you can search for `hello(` to find all invocations of the function.
                3. If you think some specific structure is repeated in the codebase, you can search for common parts of the structure.

                For example, if you find:

                ```
                %{
                  type: "function",
                  function: %{
                    name: "keyword_search",
                    description: "something"
                    ...
                  }
                }
                ```

                And you want something similar in other files, you might want to search `type: "function",` or `function: %{`.
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
