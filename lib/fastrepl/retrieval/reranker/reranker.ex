defmodule Fastrepl.Retrieval.Reranker do
  alias Fastrepl.Retrieval

  @callback rerank([Retrieval.Result.t()]) :: [Retrieval.Result.t()]
  def run(items), do: impl() |> Enum.reduce(items, fn module, acc -> module.rerank(acc) end)

  defp impl do
    [Retrieval.Reranker.Frequency]
  end
end
