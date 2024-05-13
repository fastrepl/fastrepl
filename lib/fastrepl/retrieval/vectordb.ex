defmodule Fastrepl.Retrieval.Vectordb do
  alias Fastrepl.Retrieval.Embedding

  @default_tok_k 5
  @default_threshold 0.5

  def query(query, docs, opts \\ []) do
    top_k = Keyword.get(opts, :top_k, @default_tok_k)
    threshold = Keyword.get(opts, :threshold, @default_threshold)

    texts = Enum.map(docs, &to_string/1)

    {:ok, embeddings} = Embedding.generate([query | texts])
    embeddings = Nx.tensor(embeddings)

    {q_tensor, docs_tensor} = Nx.split(embeddings, 1, axis: 0)
    q_tensor = Nx.transpose(q_tensor)

    q_norm = q_tensor |> Nx.pow(2) |> Nx.sum() |> Nx.sqrt()
    docs_norm = docs_tensor |> Nx.pow(2) |> Nx.sum(axes: [1]) |> Nx.sqrt()

    cosine_similarity =
      Nx.dot(docs_tensor, q_tensor)
      |> Nx.squeeze()
      |> Nx.divide(Nx.multiply(docs_norm, q_norm))

    {values, indices} = Nx.top_k(cosine_similarity, k: min(top_k, length(texts)))

    Enum.zip(Nx.to_list(values), Nx.to_list(indices))
    |> Enum.filter(fn {score, _index} -> score >= threshold end)
    |> Enum.take(top_k)
    |> Enum.map(fn {_score, index} -> Enum.at(docs, index) end)
  end
end
