defmodule Fastrepl.Writer do
  alias LangChain.Chains.LLMChain
  alias LangChain.ChatModels.ChatOpenAI, as: ChatModel
  alias LangChain.Message
  alias LangChain.Function

  @model_id "gpt-3.5-turbo-0125"

  @spec thread_summary(info :: String.Chars.t()) :: String.t()
  def thread_summary(info) do
    func =
      Function.new!(%{
        name: "save",
        parameters_schema: %{
          type: "object",
          properties: %{
            description: %{
              type: "string",
              description: "Simple one-line description of the given text."
            }
          },
          required: ["description"]
        }
      })

    instruction = """
    <query_to_save>
    #{info |> to_string() |> String.trim()}
    </query_to_save>

    Considering text enclosed in <query_to_save>, summarize, paraphrase, and describe the conversation in a concise manner.
    And then, save it using the function "save".

    Example description:
    "A simple greeting."
    "Anlyzing code snippets with OpenAI and LangChain."
    "Optimizing memory usage in Rust structs."
    """

    {:ok, _, %Message{} = message} =
      LLMChain.new!(%{llm: ChatModel.new!(%{model: @model_id, stream: false})})
      |> LLMChain.add_functions(func)
      |> LLMChain.add_message(Message.new_user!(instruction))
      |> LLMChain.run()

    if message.arguments do
      message.arguments["description"]
    else
      info |> to_string() |> String.trim() |> String.slice(0..20)
    end
  end
end