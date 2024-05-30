defmodule Fastrepl.XML do
  @pattern ~r/<(\w+)>(.*?)<\/\1>/s

  def parse(input) do
    case Regex.scan(@pattern, input) do
      [] ->
        input

      matches ->
        matches |> Enum.map(fn [_, tag, content] -> {tag, parse(content)} end)
    end
  end
end
