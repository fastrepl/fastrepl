defmodule Fastrepl.URL do
  @spec from(String.t()) :: [String.t()]
  def from(text) when is_binary(text) do
    regex =
      ~r/(?:(?:https?):\/\/|www\.)(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#\/%=~_|$?!:,.])*(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[A-Z0-9+&@#\/%=~_|$])/i

    text
    |> then(&Regex.scan(regex, &1))
    |> List.flatten()
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn url -> url == "" end)
  end

  def from(_), do: []
end
