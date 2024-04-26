defmodule Fastrepl.Retrieval.Embedding do
  @callback generate(String.t() | [String.t()]) :: {:ok, [[float()]]} | {:error, any()}
end

defmodule Fastrepl.Retrieval.Embedding.Cache do
  defmacro __using__(_opts) do
    quote do
      @generate_batch_size 50

      def generate_with_cache(texts) do
        {cached, not_cached} =
          texts
          |> Enum.map(&get_cache/1)
          |> Enum.with_index()
          |> Enum.split_with(fn {result, _index} -> result |> elem(0) == :ok end)

        cached_map =
          cached
          |> Enum.map(fn {data, index} -> {index, data |> elem(1)} end)
          |> Map.new()

        fetched_map =
          not_cached
          |> Enum.map(fn {_, index} -> {index, Enum.at(texts, index)} end)
          |> Enum.chunk_every(@generate_batch_size)
          |> Enum.flat_map(fn batch ->
            batch_texts = Enum.map(batch, fn {_, text} -> text end)
            {:ok, generated_embeddings} = __MODULE__.generate(batch_texts)
            Enum.zip(batch, generated_embeddings)
          end)
          |> Map.new(fn {{index, _}, embedding} -> {index, embedding} end)

        fetched_map
        |> Enum.each(fn {index, embedding} ->
          set_cache(texts |> Enum.at(index), embedding)
        end)

        ret =
          Map.merge(cached_map, fetched_map)
          |> Enum.sort_by(fn {index, _} -> index end)
          |> Enum.map(fn {_, embedding} -> embedding end)

        {:ok, ret}
      end

      defp cache_module() do
        Application.fetch_env!(:fastrepl, :cache)
      end

      defp get_key(text) do
        key = :crypto.hash(:sha256, text) |> Base.encode16(case: :lower)
        "fastrepl:embedding:#{key}"
      end

      defp get_cache(text) do
        text |> get_key() |> cache_module().get()
      end

      defp set_cache(text, embedding) do
        text |> get_key() |> cache_module().set(embedding)
      end

      defoverridable generate_with_cache: 1
    end
  end
end
