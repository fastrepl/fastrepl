defmodule Fastrepl.ChunckerTest do
  @moduledoc """
  Detailed tests should be placed on the Rust side.
  """

  use ExUnit.Case, async: true

  alias Fastrepl.Retrieval.Chunker

  describe "chunk_code/2" do
    test "it works 1" do
      chunks = Chunker.chunk_code("test.unknown", "const a = 1;\n" |> String.duplicate(500))
      assert chunks |> get_in([Access.at(0), Access.key!(:file_path)]) == "test.unknown"

      assert length(chunks) == 3
      assert(chunks |> get_in([Access.at(0), Access.key!(:span)]) == {1, 200})
    end

    test "it works 2" do
      chunks = Chunker.chunk_code("test.js", "const a = 1;\n" |> String.duplicate(500))
      assert chunks |> get_in([Access.at(0), Access.key!(:file_path)]) == "test.js"
      assert length(chunks) == 3
    end
  end

  describe "version/0" do
    test "it works" do
      assert Chunker.version() == 0
    end
  end
end
