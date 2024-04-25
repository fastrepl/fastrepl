defmodule Fastrepl.Retrieval.Embedding do
  @callback generate(String.t() | [String.t()]) :: {:ok, [[float()]]} | {:error, any()}
  @callback generate!(String.t() | [String.t()]) :: [[float()]]
end
