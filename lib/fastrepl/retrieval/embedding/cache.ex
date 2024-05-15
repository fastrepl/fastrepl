defmodule Fastrepl.Retrieval.Embedding.Cache do
  @moduledoc """
  Expects a module to implement `generate_without_cache/1`.
  """

  defmacro __using__(_opts) do
    quote do
      def generate(texts) do
        {cached, not_cached} =
          texts
          |> Enum.map(&get_cache/1)
          |> Enum.with_index()
          |> Enum.split_with(fn {result, _index} -> result |> elem(0) == :ok end)

        indices = not_cached |> Enum.map(&elem(&1, 1))
        texts_to_generate = indices |> Enum.map(&Enum.at(texts, &1))

        case __MODULE__.generate_without_cache(texts_to_generate) do
          {:ok, embeddings} ->
            fetched_map = Enum.zip(indices, embeddings) |> Map.new()

            fetched_map
            |> Enum.each(fn {index, embedding} ->
              set_cache(Enum.at(texts, index), embedding)
            end)

            cached_map =
              cached
              |> Enum.map(fn {data, index} -> {index, data |> elem(1)} end)
              |> Map.new()

            ret =
              Map.merge(cached_map, fetched_map)
              |> Enum.sort_by(fn {index, _} -> index end)
              |> Enum.map(fn {_, embedding} -> embedding end)

            {:ok, ret}

          {:error, error} ->
            {:error, error}
        end
      end

      defp get_key(text) do
        hash = :crypto.hash(:sha256, text) |> Base.encode16(case: :lower)
        chunker_version = Fastrepl.Retrieval.Chunker.version()

        "fastrepl:embedding:#{hash}#{chunker_version}"
      end

      defp get_cache(text) do
        text |> get_key() |> Fastrepl.Cache.get()
      end

      defp set_cache(text, embedding) do
        text |> get_key() |> Fastrepl.Cache.set(embedding)
      end
    end
  end
end
