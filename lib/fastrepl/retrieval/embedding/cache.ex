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

        cached_map =
          cached
          |> Enum.map(fn {data, index} -> {index, data |> elem(1)} end)
          |> Map.new()

        indices = not_cached |> Enum.map(&elem(&1, 1))
        texts_to_generate = indices |> Enum.map(&Enum.at(texts, &1))
        {:ok, embeddings} = __MODULE__.generate_without_cache(texts_to_generate)

        fetched_map = Enum.zip(indices, embeddings) |> Map.new()

        fetched_map
        |> Enum.each(fn {index, embedding} ->
          set_cache(Enum.at(texts, index), embedding)
        end)

        ret =
          Map.merge(cached_map, fetched_map)
          |> Enum.sort_by(fn {index, _} -> index end)
          |> Enum.map(fn {_, embedding} -> embedding end)

        {:ok, ret}
      end

      defp get_key(text) do
        key = :crypto.hash(:sha256, text) |> Base.encode16(case: :lower)
        "fastrepl:embedding:#{key}"
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