defmodule Fastrepl.ChunckerTest do
  @moduledoc """
  Detailed tests should be placed on the Rust side.
  """

  use ExUnit.Case, async: true

  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Chunker.Chunk

  describe "to_string/1" do
    test "single span" do
      chunk = %Chunk{
        file_path: "test.js",
        content: "const a = 1;",
        spans: [{1, 2}]
      }

      assert chunk |> to_string() ==
               """
               ```test.js#L1-L2
               const a = 1;
               ```
               """
               |> String.trim()
    end

    test "multiple spans" do
      chunk = %Chunk{
        file_path: "test.js",
        content: "const a = 1;\n" |> String.duplicate(100),
        spans: [{1, 2}, {42, 43}]
      }

      assert chunk |> to_string() ==
               """
               ```test.js#L1-L2
               const a = 1;
               const a = 1;
               ```
               ---
               ```test.js#L42-L43
               const a = 1;
               const a = 1;
               ```
               """
               |> String.trim()
    end
  end

  describe "merge/2" do
    test "non-overlapping" do
      chunk1 = %Chunk{file_path: "test.js", spans: [{1, 2}]}
      chunk2 = %Chunk{file_path: "test.js", spans: [{3, 4}]}

      assert Chunk.merge(chunk1, chunk2).spans == [{1, 2}, {3, 4}]
    end
  end

  describe "chunk_code/2" do
    test "it works 1" do
      chunks = Chunker.chunk_code("test.unknown", "const a = 1;\n" |> String.duplicate(100))
      assert chunks |> get_in([Access.at(0), Access.key!(:file_path)]) == "test.unknown"
      assert length(chunks) == 3
      assert chunks |> get_in([Access.at(0), Access.key!(:spans)]) == [{1, 50}]
    end

    test "it works 2" do
      chunks = Chunker.chunk_code("test.js", "const a = 1;\n" |> String.duplicate(100))
      assert chunks |> get_in([Access.at(0), Access.key!(:file_path)]) == "test.js"
      assert length(chunks) == 3
    end
  end
end
