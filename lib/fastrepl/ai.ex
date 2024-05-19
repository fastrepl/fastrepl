defmodule Fastrepl.AI do
  defp client() do
    proxy_url = Application.fetch_env!(:fastrepl, :proxy_api_base)
    proxy_key = Application.fetch_env!(:fastrepl, :proxy_api_key)

    Fastrepl.req_client()
    |> Req.merge(
      base_url: proxy_url,
      headers: [{"Authorization", "Bearer #{proxy_key}"}]
    )
  end

  def embedding(request) do
    resp =
      client()
      |> Req.post(
        url: "/v1/embeddings",
        json: request
      )

    case resp do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, data |> get_in([Access.at(0), "embedding"])}

      {:ok, data} ->
        {:error, data}

      {:error, error} ->
        {:error, error}
    end
  end

  def chat(request, callback \\ fn data -> IO.inspect(data) end) do
    into = if request[:stream], do: get_handler(callback), else: nil

    resp =
      client()
      |> Req.post(
        url: "/v1/chat/completions",
        json: request,
        into: into
      )

    case resp do
      {:ok, %{body: body}} -> {:ok, body}
      {:error, error} -> {:error, error}
    end
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
  defp decode(data), do: Jason.decode!(data)
end
