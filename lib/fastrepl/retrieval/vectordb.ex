defmodule Fastrepl.Retrieval.Vectordb do
  use Agent

  @default_tok_k 5
  @default_threshold 0.5

  defp embedding_module() do
    Application.fetch_env!(:fastrepl, :embedding)
  end

  defp registry_module() do
    Application.fetch_env!(:fastrepl, :vectordb_registry)
  end

  def start(id) do
    case Registry.lookup(registry_module(), id) do
      [{pid, _value}] ->
        reset(pid)
        {:ok, pid}

      [] ->
        Agent.start(fn -> %{id: id, docs: []} end, name: via_registry(id))
    end
  end

  defp via_registry(id) do
    {:via, Registry, {registry_module(), id}}
  end

  def stop(pid) do
    id = Agent.get(pid, fn %{id: id} -> id end)
    Registry.unregister(registry_module(), id)
    Agent.stop(pid)
  end

  defp reset(pid) do
    Agent.update(pid, fn state -> %{state | docs: []} end)
  end

  def ingest(pid, docs) do
    Agent.update(pid, fn state -> state |> Map.put(:docs, state.docs ++ docs) end)

    docs
    |> Enum.map(&to_string/1)
    |> embedding_module().generate!()
  end

  def query(pid, q, opts \\ []) do
    top_k = Keyword.get(opts, :top_k, @default_tok_k)
    threshold = Keyword.get(opts, :threshold, @default_threshold)

    docs = Agent.get(pid, fn state -> state.docs end)
    texts = Enum.map(docs, &to_string/1)

    {:ok, embeddings} = embedding_module().generate([q | texts])
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
