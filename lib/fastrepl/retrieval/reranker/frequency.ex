defmodule Fastrepl.Retrieval.Reranker.Frequency do
  @behaviour Fastrepl.Retrieval.Reranker

  def rerank(items) do
    items
    |> Enum.group_by(& &1.file_path)
    |> Enum.sort_by(fn {_, items} -> length(items) end, :desc)
    |> Enum.flat_map(fn {_, items} -> items end)
  end
end
