defmodule Fastrepl.Temp do
  @default_ttl "100"

  @failed_to_set_error "failed to set value"
  @failed_to_get_error "failed to get value"
  @not_found_error "key never existed or expired"

  def set(id, str, opts \\ []) do
    ttl = Keyword.get(opts, :ttl, @default_ttl)

    case Redix.command(:redix, ["SETEX", get_key(id), ttl, :erlang.term_to_binary(str)]) do
      {:ok, _} -> :ok
      _ -> {:error, @failed_to_set_error}
    end
  end

  def get(id) do
    case Redix.command(:redix, ["GET", get_key(id)]) do
      {:ok, nil} -> {:error, @not_found_error}
      {:ok, value} -> {:ok, :erlang.binary_to_term(value)}
      _ -> {:error, @failed_to_get_error}
    end
  end

  defp get_key(id) do
    "fastrepl:temp:#{id}"
  end
end
