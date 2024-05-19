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

    test "enture max tokens" do
      root_path = System.tmp_dir!() |> Path.join(Nanoid.generate())
      Fastrepl.Native.CodeUtils.clone("https://github.com/brainlid/langchain", root_path, 1)

      chunks =
        root_path
        |> Fastrepl.FS.list_informative_files()
        |> Enum.flat_map(&Chunker.chunk_file/1)

      tokenizer = Fastrepl.Tokenizer.load!(:gpt_3_5)

      for chunk <- chunks do
        content = Fastrepl.FS.read_lines!(chunk.file_path, chunk.span)
        tokens = Fastrepl.Tokenizer.count_tokens(content, tokenizer)
        assert tokens <= 3000
      end
    end
  end

  describe "version/0" do
    test "it works" do
      assert Chunker.version() == 0
    end
  end
end
