defmodule Fastrepl.VectordbTest do
  use ExUnit.Case, async: true

  import Mox, only: [verify_on_exit!: 1]
  setup :verify_on_exit!

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Chunker.Chunk

  describe "query/3" do
    test "empty" do
      assert "" |> Vectordb.query([]) == []
    end

    test "with string" do
      Fastrepl.Retrieval.Embedding.Mock
      |> Mox.expect(:generate, 1, fn texts ->
        assert length(texts) == 3 + 1
        {:ok, [[0.1, 0.2, 0.3], [0.12, 0.22, 0.32], [0.15, 0.25, 0.35], [0.3, 0.2, 0.1]]}
      end)

      docs = ["hello", "hi", "fastrepl"]

      assert "hey" |> Vectordb.query(docs, top_k: 2, threshold: 0.1) == ["hello", "hi"]
    end

    test "with chunk" do
      Fastrepl.Retrieval.Embedding.Mock
      |> Mox.expect(:generate, 1, fn texts ->
        assert length(texts) == 3 + 1
        {:ok, [[0.1, 0.2, 0.3], [0.12, 0.22, 0.32], [0.15, 0.25, 0.35], [0.3, 0.2, 0.1]]}
      end)

      docs = [
        %Chunk{content: "hello"},
        %Chunk{content: "hi"},
        %Chunk{content: "fastrepl"}
      ]

      assert "hey" |> Vectordb.query(docs, top_k: 1, threshold: 0.1) == [%Chunk{content: "hello"}]
    end
  end
end
