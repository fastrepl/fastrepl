defmodule Fastrepl.ChunckerTest do
  @moduledoc """
  Detailed tests should be placed in the Rust side.
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

  describe "chunk_code/2" do
    test "it works 1" do
      code = "123\n456\n789" |> String.duplicate(100)
      _ = Chunker.chunk_code("test.unknown", code)
    end

    test "it works 2" do
      code = "const a = 1;\n" |> String.duplicate(100)
      _ = Chunker.chunk_code("test.js", code)
    end
  end
end
