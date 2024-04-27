defmodule Fastrepl.VectordbTest do
  use ExUnit.Case, async: true

  import Mox, only: [verify_on_exit!: 1]
  setup :verify_on_exit!

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Chunker.Chunk

  setup do
    registry_name = __MODULE__ |> Module.concat(Nanoid.generate())
    {:ok, _} = Registry.start_link(keys: :unique, name: registry_name)
    Application.put_env(:fastrepl, :vectordb_registry, registry_name)
  end

  describe "query/3" do
    test "with string" do
      {:ok, pid} = Vectordb.start(Nanoid.generate())

      Fastrepl.Retrieval.Embedding.Mock
      |> Mox.expect(:generate, 1, fn texts ->
        assert length(texts) == 3
        {:ok, [[0.12, 0.22, 0.32], [0.15, 0.25, 0.35], [0.3, 0.2, 0.1]]}
      end)
      |> Mox.expect(:generate, 1, fn texts ->
        assert length(texts) == 3 + 1
        {:ok, [[0.1, 0.2, 0.3], [0.12, 0.22, 0.32], [0.15, 0.25, 0.35], [0.3, 0.2, 0.1]]}
      end)

      Vectordb.ingest(pid, ["hello", "hi", "fastrepl"])
      assert Vectordb.query(pid, "hey", top_k: 2, threshold: 0.1) == ["hello", "hi"]

      Vectordb.stop(pid)
    end

    test "with chunk" do
      {:ok, pid} = Vectordb.start(Nanoid.generate())

      Fastrepl.Retrieval.Embedding.Mock
      |> Mox.expect(:generate, 1, fn texts ->
        assert length(texts) == 3
        {:ok, [[0.12, 0.22, 0.32], [0.15, 0.25, 0.35], [0.3, 0.2, 0.1]]}
      end)
      |> Mox.expect(:generate, 1, fn texts ->
        assert length(texts) == 3 + 1
        {:ok, [[0.1, 0.2, 0.3], [0.12, 0.22, 0.32], [0.15, 0.25, 0.35], [0.3, 0.2, 0.1]]}
      end)

      Vectordb.ingest(pid, [
        %Chunk{content: "hello"},
        %Chunk{content: "hi"},
        %Chunk{content: "fastrepl"}
      ])

      assert Vectordb.query(pid, "hey", top_k: 1, threshold: 0.1) == [%Chunk{content: "hello"}]

      Vectordb.stop(pid)
    end
  end
end
