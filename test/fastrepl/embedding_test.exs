defmodule Fastrepl.EmbeddingTest do
  use ExUnit.Case, async: true

  import Mox, only: [verify_on_exit!: 1]
  setup :verify_on_exit!

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

    Fastrepl.Cache.Mock
    |> Mox.expect(:get, 3, fn _key -> {:error, nil} end)
    |> Mox.expect(:set, 3, fn _key, _value -> :ok end)
    |> Mox.expect(:get, 1, fn _key -> {:ok, [1]} end)
    |> Mox.expect(:get, 2, fn _key -> {:error, nil} end)
    |> Mox.expect(:set, 2, fn _key, _value -> :ok end)

    assert MockEmbeddingWithCache.generate(["1", "22", "333"]) ==
             {:ok, [[1], [2], [3]]}

    assert MockEmbeddingWithCache.generate(["1", "4444", "55555"]) ==
             {:ok, [[1], [4], [5]]}
  end
end
