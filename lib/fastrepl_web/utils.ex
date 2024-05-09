defmodule FastreplWeb.Utils do
  def clsx(list) do
    list
    |> Enum.reject(&(&1 == nil))
    |> Enum.reject(&(&1 == false))
    |> Enum.map(&to_string/1)
    |> Enum.join(" ")
  end
end
