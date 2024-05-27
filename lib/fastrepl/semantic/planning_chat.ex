defmodule Fastrepl.SemanticFunction.PlanningChat do
  def run(%{messages: msgs, references: _refs}, callback \\ fn data -> IO.inspect(data) end) do
    messages = [
      %{
        role: "system",
        content: """
        You are a helpful coding assistant.
        """
      },
      %{
        role: "user",
        content: """
        These are recent conversations:
        #{msgs |> Enum.map(&"#{&1["role"]}: #{&1["content"]}") |> Enum.join("\n")}

        Now, respond to the user.
        """
      }
    ]

    request(messages, callback)
  end

  defp request(messages, original_callback) do
    calllback = fn %{"choices" => [%{"delta" => delta}]} ->
      if delta["content"] do
        original_callback.({:delta, delta["content"]})
      end
    end

    Fastrepl.AI.chat(
      %{
        model: "gpt-4o",
        stream: true,
        temperature: 0,
        messages: messages
      },
      callback: calllback,
      otel_attrs: %{module: __MODULE__}
    )
  end
end
