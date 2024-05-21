defmodule Fastrepl.Tokenizer do
  @tokenizer_ids %{
    llama_2: "NousResearch/Llama-2-7b-hf",
    llama_3: "NousResearch/Meta-Llama-3-8B",
    gpt_3_5: "Xenova/gpt-3.5-turbo",
    gpt_4: "Xenova/gpt-4",
    claude: "Xenova/claude-tokenizer"
  }

  def load!(:llama_2), do: load_tokenizer!(@tokenizer_ids.llama_2, nil)
  def load!(:llama_3), do: load_tokenizer!(@tokenizer_ids.llama_3, nil)
  def load!(:gpt_3_5), do: load_tokenizer!(@tokenizer_ids.gpt_3_5, :gpt2)
  def load!(:gpt_4), do: load_tokenizer!(@tokenizer_ids.gpt_4, :gpt2)
  def load!(:claude), do: load_tokenizer!(@tokenizer_ids.claude, :gpt2)

  defp load_tokenizer!(id, type) do
    {:ok, tokenizer} = Bumblebee.load_tokenizer({:hf, id, cache_dir: "./.cache"}, type: type)
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
    |> String.trim()
  end

  def count_tokens("", _), do: 0

  def count_tokens(text, tokenizer) do
    tokenizer
    |> Bumblebee.apply_tokenizer(text)
    |> Map.get("token_type_ids")
    |> Nx.shape()
    |> elem(1)
  end
end
