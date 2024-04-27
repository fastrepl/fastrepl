defmodule Fastrepl.ChunckerTest do
  @moduledoc """
  Detailed tests should be placed on the Rust side.
  """

  use ExUnit.Case, async: true

  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Chunker.Chunk

  describe "to_string/1" do
    test "simple" do
      chunk = %Chunk{
        file_path: "test.js",
        content: "const a = 1;",
        line_start: 1,
        line_end: 2
      }

      assert chunk |> to_string() ==
               """
               ```test.js#L1-L2
               const a = 1;
               ```
               """
               |> String.trim()
    end
  end

  describe "chunk_file/2" do
    setup do
      code = "const a = 1;\n" |> String.duplicate(100)
      path_unknown = System.tmp_dir!() |> Path.join("test.unknown")
      path_js = System.tmp_dir!() |> Path.join("test.js")

      File.write!(path_unknown, code)
      File.write!(path_js, code)

      on_exit(fn ->
        File.rm!(path_unknown)
        File.rm!(path_js)
      end)

      {:ok, %{path_unknown: path_unknown, path_js: path_js}}
    end

    test "it works 1", %{path_unknown: path_unknown} do
      chunks = Chunker.chunk_file(path_unknown)
      assert chunks |> get_in([Access.at(0), Access.key!(:file_path)]) == path_unknown
      assert length(chunks) == 3
    end

    test "it works 2", %{path_js: path_js} do
      chunks = Chunker.chunk_file(path_js)
      assert chunks |> get_in([Access.at(0), Access.key!(:file_path)]) == path_js
      assert length(chunks) == 3
    end
  end
end
