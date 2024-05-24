defmodule Fastrepl.AI do
  use Retry
  use Tracing

  import Fastrepl, only: [trim: 1]

  defp client() do
    proxy_url = Application.fetch_env!(:fastrepl, :proxy_api_base)
    proxy_key = Application.fetch_env!(:fastrepl, :proxy_api_key)

    Fastrepl.rest_client(
      base_url: proxy_url,
      headers: [{"Authorization", "Bearer #{proxy_key}"}]
    )
  end

  def embedding(request, opts \\ []) do
    opts = Keyword.merge([otel_attrs: %{}], opts)

    resp =
      retry with: exponential_backoff() |> randomize |> cap(1_000) |> expiry(4_000) do
        client()
        |> Req.post(
          url: "/v1/embeddings",
          json: request,
          otel_attrs: opts[:otel_attrs]
        )
      end

    case resp do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, data |> get_in([Access.at(0), "embedding"])}

      {:ok, data} ->
        {:error, data}

      {:error, error} ->
        {:error, error}
    end
  end

  def chat(request, opts \\ []) do
    opts = Keyword.merge([otel_attrs: %{}, callback: fn data -> IO.inspect(data) end], opts)
    into = if request[:stream], do: get_handler(opts[:callback]), else: nil

    request =
      request
      |> Map.update!(:messages, &trim/1)
      |> Map.update(:tools, nil, &trim/1)
      |> Map.reject(fn {_k, v} -> is_nil(v) end)

    resp =
      retry with: exponential_backoff() |> randomize |> cap(1_000) |> expiry(4_000) do
        client()
        |> Req.post(
          url: "/v1/chat/completions",
          json: request,
          into: into,
          otel_attrs: opts[:otel_attrs]
        )
      end

    case resp do
      {:ok, %{body: %{"choices" => [%{"finish_reason" => "tool_calls", "message" => message}]}}} ->
        {:ok, parse_tool_calls(message)}

      {:ok, %{body: %{"choices" => [%{"delta" => delta}]}}} ->
        {:ok, delta["content"]}

      {:ok, %{body: %{"choices" => [%{"message" => message}]}}} ->
        tool_calls = parse_tool_calls(message)

        if tool_calls != [] do
          {:ok, tool_calls}
        else
          {:ok, message["content"]}
        end

      {:ok, %{body: body}} ->
        {:ok, body}

      {:error, error} ->
        {:error, error}
    end
  end

  defp parse_tool_calls(message) do
    message
    |> get_in([Access.key("tool_calls", [])])
    |> Enum.map(fn %{"function" => f} ->
      %{
        name: f["name"],
        args: Jason.decode!(f["arguments"])
      }
    end)
  end

  defp get_handler(callback) do
    fn {:data, data}, acc ->
      Enum.each(parse(data), callback)
      {:cont, acc}
    end
  end

  defp parse(chunk) do
    chunk
    |> String.split("data: ")
    |> Enum.map(&String.trim/1)
    |> Enum.map(&decode/1)
    |> Enum.reject(&is_nil/1)
  end

  defp decode(""), do: nil
  defp decode("[DONE]"), do: nil

  defp decode(data) do
    case Jason.decode(data) do
      {:ok, r} -> r
      _ -> nil
    end
  end
end
