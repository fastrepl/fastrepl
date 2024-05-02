defprotocol Fastrepl.LLM do
  def render(data)
end

defimpl Fastrepl.LLM, for: String do
  def render(data), do: data
end

defimpl Fastrepl.LLM, for: GitHub.Issue do
  def render(%{title: title, number: number, body: body, user: %{name: name}}) do
    """
    ##{number}: #{title} (#{name})
    ---

    #{body}
    """
    |> String.trim()
  end
end

defimpl Fastrepl.LLM, for: GitHub.Issue.Comment do
  def render(%{body: body, user: %{name: name}}) do
    """
    #{name}:

    #{body}
    """
    |> String.trim()
  end
end
