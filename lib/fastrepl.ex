defmodule Fastrepl do
  use Tracing

  def chat_model(attrs) do
    proxy = %{
      api_key: Application.fetch_env!(:fastrepl, :proxy_api_key),
      endpoint: "#{Application.fetch_env!(:fastrepl, :proxy_api_base)}/v1/chat/completions"
    }

    attrs
    |> Map.merge(proxy)
    |> LangChain.ChatModels.ChatOpenAI.new!()
  end

  def req_client() do
    Req.new()
    |> OpentelemetryReq.attach(no_path_params: true)
    |> Req.Request.register_options([:otel_attrs])
    |> Req.Request.append_request_steps(
      otel_attrs: fn req ->
        attrs = req.options |> Map.get(:otel_attrs, %{})
        for {k, v} <- attrs, do: Tracing.set_attribute(k, v)

        req
      end
    )
  end
end
