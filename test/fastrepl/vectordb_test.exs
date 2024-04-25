defmodule Fastrepl.VectordbTest do
  use ExUnit.Case, async: true

  alias Fastrepl.Retrieval.Vectordb
  alias Fastrepl.Retrieval.Chunker.Chunk

  defmodule MockEmbedding do
    @behaviour Fastrepl.Retrieval.Embedding

    def generate(texts) do
      {:ok, generate!(texts)}
    end

    def generate!(texts) do
      texts
      |> Enum.map(fn text ->
        cond do
          text |> to_string() |> String.contains?("hey") -> [0.1, 0.2, 0.3]
          text |> to_string() |> String.contains?("hello") -> [0.12, 0.22, 0.32]
          text |> to_string() |> String.contains?("hi") -> [0.15, 0.25, 0.35]
          text |> to_string() |> String.contains?("fastrepl") -> [0.3, 0.2, 0.1]
        end
      end)
    end
  end

  setup do
    {:ok, pid} = Registry.start_link(keys: :unique, name: __MODULE__)

    Application.put_env(:fastrepl, :embedding, MockEmbedding)
    Application.put_env(:fastrepl, :vectordb_registry, __MODULE__)

    on_exit(fn ->
      Application.put_env(:fastrepl, :embedding, nil)
      Application.put_env(:fastrepl, :vectordb_registry, nil)
      Process.exit(pid, :normal)
    end)
  end

  describe "query/3" do
    test "string" do
      {:ok, pid} = Vectordb.start(Nanoid.generate())

      Vectordb.ingest(pid, ["hello", "hi", "fastrepl"])

      assert Vectordb.query(pid, "hey", top_k: 2, threshold: 0.1) == ["hello", "hi"]
      Vectordb.stop(pid)
    end

    test "chunk" do
      {:ok, pid} = Vectordb.start(Nanoid.generate())

      Vectordb.ingest(pid, [
        %Chunk{content: "hello"},
        %Chunk{content: "hi"},
        %Chunk{content: "fastrepl"}
      ])

      assert Vectordb.query(pid, "hey", top_k: 1, threshold: 0.1) == [%Chunk{content: "hello"}]

      assert Vectordb.query(pid, "hey", top_k: 3, threshold: 0.1) == [
               %Chunk{content: "hello"},
               %Chunk{content: "hi"},
               %Chunk{content: "fastrepl"}
             ]

      assert Vectordb.query(pid, "hey", top_k: 3, threshold: 0.8) == [
               %Chunk{content: "hello"},
               %Chunk{content: "hi"}
             ]

      Vectordb.stop(pid)
    end
  end
end
