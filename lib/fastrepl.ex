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

  def rest_client(opts \\ []) do
    Req.new(opts)
    |> attach_otel()
  end

  def graphql_client(opts \\ []) do
    Req.new(opts)
    |> attach_otel()
    |> AbsintheClient.attach()
    |> Req.Request.register_options([:graphql])
  end

  defp attach_otel(req) do
    req
    |> Req.Request.register_options([:otel_attrs])
    |> Req.Request.append_request_steps(
      otel_attrs: fn req ->
        attrs = req.options |> Map.get(:otel_attrs, %{})
        for {k, v} <- attrs, do: Tracing.set_attribute(k, v)

        req
      end
    )
  end

  def trim(data) when is_list(data), do: Enum.map(data, &trim/1)

  def trim(data) when is_map(data) do
    data |> Map.new(fn {k, v} -> {k, trim(v)} end)
  end

  def trim(data) when is_binary(data), do: String.trim(data)
  def trim(data), do: data
end
