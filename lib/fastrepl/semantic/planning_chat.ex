defmodule Fastrepl.SemanticFunction.PlanningChat do
  use Retry

  alias LangChain.Chains.LLMChain
  alias LangChain.Message

  def run(
        %{messages: msgs, references: _refs},
        callback \\ fn data -> IO.puts(inspect(data)) end
      ) do
    messages = [
      Message.new_system!("You are a helpful coding assistant."),
      Message.new_user!("""
      These are recent conversations:
      #{msgs |> Enum.map(&"#{&1["role"]}: #{&1["content"]}") |> Enum.join("\n")}

      Now, respond to the user.
      """)
    ]

    retry with:
            exponential_backoff()
            |> randomize
            |> cap(1_000)
            |> expiry(4_000) do
      request(messages, callback)
    after
      {:ok, _, %Message{} = message} ->
        {:ok, message}
    else
      error -> error
    end
  end

  defp request(messages, original_callback_fn) do
    wrapped_callback_fn = fn
      %LangChain.MessageDelta{} = message ->
        if message.content do
          original_callback_fn.({:update, message.content})
        end

      %LangChain.Message{} = message ->
        if message.content do
          original_callback_fn.({:complete, message.content})
        end
    end

    LLMChain.new!(%{
      llm: Fastrepl.chat_model(%{model: "gpt-4-turbo", stream: false, temperature: 0})
    })
    |> LLMChain.add_messages(messages)
    |> LLMChain.run(callback_fn: wrapped_callback_fn)
  end
end
