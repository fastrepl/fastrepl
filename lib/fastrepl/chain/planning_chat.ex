defmodule Fastrepl.Chain.PlanningChat do
  use Retry

  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI, as: ChatModel
  alias LangChain.Message

  @model_id "gpt-4-turbo-2024-04-09"

  def run(text, callback \\ fn data -> IO.puts(inspect(data)) end) do
    messages = [
      Message.new_system!(
        """
        You are a helpful coding assistant.
        """
        |> String.trim()
      ),
      Message.new_user!(text |> String.trim())
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

    LLMChain.new!(%{llm: ChatModel.new!(%{model: @model_id, stream: true, temperature: 0})})
    |> LLMChain.add_messages(messages)
    |> LLMChain.run(callback_fn: wrapped_callback_fn)
  end
end
