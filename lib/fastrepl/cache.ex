defmodule Fastrepl.Cache do
  @callback get(binary()) :: term()
  @callback set(binary(), term()) :: :ok | {:error, any()}
end

defmodule Fastrepl.Cache.Redis do
  @behaviour Fastrepl.Cache

  def get(key) do
    case Redix.command(:redix, ["GET", key]) do
      {:ok, nil} -> {:error, "Not found"}
      {:ok, value} -> {:ok, :erlang.binary_to_term(value)}
      _ -> {:error, "Failed to get value"}
    end
  end

  def set(key, value) do
    case Redix.command(:redix, ["SET", key, :erlang.term_to_binary(value)]) do
      {:ok, _} -> :ok
      _ -> {:error, "Failed to set value"}
    end
  end
end

defmodule Fastrepl.Cache.InMemory do
  @behaviour Fastrepl.Cache

  def get(key) do
    case Process.get(key) do
      nil -> {:error, "Not found"}
      value -> {:ok, value}
    end
  end

  def set(key, value) do
    Process.put(key, value)
    :ok
  end
end
