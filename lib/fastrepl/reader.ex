defmodule Fastrepl.Reader do
  alias Readability

  def from_url!(url) do
    Req.get!(url: url)
    |> Map.get(:body)
    |> from_html()
  end

  def from_html(html) do
    html
    |> Readability.article()
    |> Readability.readable_text()
  end
end
