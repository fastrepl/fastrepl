defmodule Fastrepl.EmbeddingTest do
  use ExUnit.Case, async: true

  setup do
    Application.put_env(:fastrepl, :cache, Fastrepl.Cache.InMemory)
  end

  test "it works" do
    defmodule MockEmbedding do
      @behaviour Fastrepl.Retrieval.Embedding

      def generate(texts) do
        {:ok, Enum.map(texts, fn text -> [String.length(text)] end)}
      end
    end

    defmodule MockEmbeddingWithCache do
      @behaviour Fastrepl.Retrieval.Embedding
      use Fastrepl.Retrieval.Embedding.Cache

      def generate_without_cache(texts) do
        {:ok, Enum.map(texts, fn text -> [String.length(text)] end)}
      end
    end

    assert MockEmbedding.generate(["1", "22", "333"]) == {:ok, [[1], [2], [3]]}

    assert MockEmbeddingWithCache.generate(["1", "22", "333"]) ==
             {:ok, [[1], [2], [3]]}

    assert MockEmbeddingWithCache.generate(["1", "22", "333"]) ==
             {:ok, [[1], [2], [3]]}

    assert MockEmbeddingWithCache.generate(["1", "22", "333"]) ==
             {:ok, [[1], [2], [3]]}

    {:ok, embeddings} = MockEmbeddingWithCache.generate(List.duplicate("1", 500))
    assert Enum.count(embeddings) == 500
  end
end
