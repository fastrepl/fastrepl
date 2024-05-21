defmodule Fastrepl.Retrieval.Embedding.OpenAI do
  @behaviour Fastrepl.Retrieval.Embedding

  @model "text-embedding-3-small"
  @dimensions 512
  # @max_input_tokens 8191
  # @max_batch_size 2048

  def generate([]) do
    {:ok, []}
  end

  @spec generate(String.t() | [String.t()]) :: {:ok, [[float()]]} | {:error, any()}
  def generate(texts) do
    data = %{
      input: texts,
      model: @model,
      encoding_format: "float",
      dimensions: @dimensions
    }

    Fastrepl.AI.embedding(data)
  end
end

defmodule Fastrepl.Retrieval.Embedding.OpenAIWithCache do
  @behaviour Fastrepl.Retrieval.Embedding
  use Fastrepl.Retrieval.Embedding.Cache

  def generate_without_cache(texts) do
    Fastrepl.Retrieval.Embedding.OpenAI.generate(texts)
  end
end
