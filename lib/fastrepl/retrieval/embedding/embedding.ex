defmodule Fastrepl.Retrieval.Embedding do
  @callback generate(String.t() | [String.t()]) :: {:ok, [[float()]]} | {:error, any()}

  def generate(texts), do: impl().generate(texts)

  defp impl do
    Application.get_env(:fastrepl, :embedding, Fastrepl.Retrieval.Embedding.OpenAIWithCache)
  end
end
