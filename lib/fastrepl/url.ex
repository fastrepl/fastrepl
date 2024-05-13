defmodule Fastrepl.URL do
  @spec from(String.t()) :: [String.t()]
  def from(text) do
    regex =
      ~r/(?:(?:https?|ftp|file):\/\/|www\.|ftp\.)(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[-A-Z0-9+&@#\/%=~_|$?!:,.])*(?:\([-A-Z0-9+&@#\/%=~_|$?!:,.]*\)|[A-Z0-9+&@#\/%=~_|$])/i

    text
    |> then(&Regex.scan(regex, &1))
    |> List.flatten()
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn url -> url == "" end)
  end
end