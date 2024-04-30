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

  describe "dedupe/1" do
    test "noop" do
      chunks = [
        %Chunk{file_path: "test1.js", spans: [{1, 2}]},
        %Chunk{file_path: "test2.js", spans: [{9, 10}]}
      ]

      assert Chunker.dedupe(chunks) == chunks
    end

    test "no overlap" do
      from = [
        %Chunk{file_path: "test1.js", spans: [{1, 2}]},
        %Chunk{file_path: "test1.js", spans: [{4, 6}]}
      ]

      to = [
        %Chunk{file_path: "test1.js", spans: [{1, 2}, {4, 6}]}
      ]

      assert Chunker.dedupe(from) == to
    end

    test "overlap_1" do
      from = [
        %Chunk{file_path: "test1.js", spans: [{1, 2}]},
        %Chunk{file_path: "test1.js", spans: [{3, 4}]}
      ]

      to = [%Chunk{file_path: "test1.js", spans: [{1, 4}]}]

      assert Chunker.dedupe(from) == to
    end

    test "overlap_2" do
      from = [
        %Chunk{file_path: "test1.js", spans: [{1, 4}]},
        %Chunk{file_path: "test1.js", spans: [{2, 6}]}
      ]

      to = [%Chunk{file_path: "test1.js", spans: [{1, 6}]}]

      assert Chunker.dedupe(from) == to
    end

    test "complex" do
      from = [
        %Chunk{file_path: "test1.js", spans: [{1, 2}]},
        %Chunk{file_path: "test2.js", spans: [{2, 5}]},
        %Chunk{file_path: "test1.js", spans: [{4, 6}]},
        %Chunk{file_path: "test2.js", spans: [{1, 7}]}
      ]

      to = [
        %Chunk{file_path: "test1.js", spans: [{1, 2}, {4, 6}]},
        %Chunk{file_path: "test2.js", spans: [{1, 7}]}
      ]

      assert Chunker.dedupe(from) == to
    end
  end

  describe "version/0" do
    test "it works" do
      assert Chunker.version() == 0
    end
  end
end
