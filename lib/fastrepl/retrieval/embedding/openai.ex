defmodule Fastrepl.Retrieval.Embedding.OpenAI do
  @behaviour Fastrepl.Retrieval.Embedding

  use Retry
  require Logger
  alias Fastrepl.Tokenizer

  @url "https://api.openai.com/v1/embeddings"
  @model "text-embedding-3-small"
  @dimensions 512
  @max_input_tokens 8191
  # @max_batch_size 2048

  @spec generate(String.t() | [String.t()]) :: {:ok, [[float()]]} | {:error, any()}
  def generate(texts) do
    retry with:
            exponential_backoff()
            |> randomize
            |> cap(1_000)
            |> expiry(6_000),
          atoms: [:error] do
      request(texts)
    after
      {:ok, result} ->
        embedding = result |> Enum.sort_by(& &1["index"]) |> Enum.map(& &1["embedding"])
        {:ok, embedding}

      :context_length_exceeded ->
        tok = Tokenizer.load(:llama)

        texts
        |> Enum.map(&Tokenizer.truncate(&1, tok, @max_input_tokens - 200))
        |> generate
    else
      error -> error
    end
  end

  defp request(texts) do
    api_key = Application.get_env(:langchain, :openai_key)

    headers = [
      {"Authorization", "Bearer #{api_key}"},
      {"Content-Type", "application/json"}
    ]

    body = %{
      input: texts,
      model: @model,
      encoding_format: "float",
      dimensions: @dimensions
    }

    case Req.post(url: @url, headers: headers, json: body) do
      {:ok, %{status: 200, body: %{"data" => data}}} ->
        {:ok, data}

      {:ok, %{body: %{"error" => %{"message" => message}}}} ->
        if String.contains?(message, "maximum context length") do
          :context_length_exceeded
        else
          {:error, message}
        end

      {:error, exception} ->
        {:error, exception}
    end
  end
end

defmodule Fastrepl.Retrieval.Embedding.OpenAIWithCache do
  @behaviour Fastrepl.Retrieval.Embedding
  use Fastrepl.Retrieval.Embedding.Cache

  def generate_without_cache(texts) do
    Fastrepl.Retrieval.Embedding.OpenAI.generate(texts)
  end
end
