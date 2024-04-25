defmodule Fastrepl.Tokenizer do
  @tokenizer_ids %{
    llama: "NousResearch/Llama-2-7b-hf"
  }

  def load(:llama), do: load_tokenizer(@tokenizer_ids.llama)

  defp load_tokenizer(id) do
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, id, cache_dir: "./.cache"})
    tokenizer
  end

  def truncate(_text, _tokenizer, max_tokens) when max_tokens <= 0, do: ""

  def truncate(text, tokenizer, max_tokens) do
    total_ids = tokenizer |> Bumblebee.apply_tokenizer(text) |> Map.get("input_ids")
    total_ids_size = Nx.shape(total_ids) |> elem(1)

    start_index = max(0, total_ids_size - max_tokens)
    end_index = total_ids_size - start_index

    truncated_ids = total_ids |> Nx.slice([0, start_index], [1, end_index])

    tokenizer
    |> Bumblebee.Tokenizer.decode(truncated_ids)
    |> get_in([Access.at(0)])
  end

  def count_tokens(text, tokenizer) do
    tokenizer
    |> Bumblebee.apply_tokenizer(text)
    |> Map.get("token_type_ids")
    |> Nx.shape()
    |> elem(1)
  end
end
