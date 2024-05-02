defmodule Fastrepl.Reader do
  alias Readability

  def text_from_url(url, timeout \\ 1_000) do
    case Req.get(url: url, receive_timeout: timeout) do
      {:ok, %{body: body}} -> text_from_html(body)
      _ -> ""
    end
  end

  def text_from_html(html) do
    html
    |> Readability.article()
    |> Readability.readable_text()
  end

  def urls_from_text(text) do
    regex =
      ~r/https?:\/\/(?:www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b(?:[-a-zA-Z0-9()@:%_\+.~#?&\/=]*)/

    text
    |> then(&Regex.scan(regex, &1))
    |> List.flatten()
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn url -> url == "" end)
  end
end
