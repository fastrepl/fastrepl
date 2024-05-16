defmodule Fastrepl do
  def chat_model(attrs) do
    proxy = %{
      api_key: Application.fetch_env!(:fastrepl, :proxy_api_key),
      endpoint: "#{Application.fetch_env!(:fastrepl, :proxy_api_base)}/v1/chat/completions"
    }

    attrs
    |> Map.merge(proxy)
    |> LangChain.ChatModels.ChatOpenAI.new!()
  end
end
