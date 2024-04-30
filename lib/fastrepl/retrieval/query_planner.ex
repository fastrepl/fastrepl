defmodule Fastrepl.Retrieval.QueryPlanner do
  @base_url "https://api.openai.com/v1"
  @model_id "gpt-4-turbo-2024-04-09"

  use Retry

  def run(query) do
    retry with:
            exponential_backoff()
            |> randomize
            |> cap(1_000)
            |> expiry(4_000) do
      request(query)
    after
      {:ok, res} ->
        tool_calls =
          res.body
          |> get_in(["choices", Access.at(0), "message", "tool_calls"]) || []

        tool_calls =
          tool_calls
          |> Enum.map(fn %{"function" => f} -> {f["name"], Jason.decode!(f["arguments"])} end)

        {:ok, tool_calls}
    else
      error -> error
    end
  end

  @embedding %{
    type: "function",
    function: %{
      name: "semantic_search",
      description: "use embedding and cosine similarity to find relevant code snippets",
      parameters: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "Description about the code snippets to retrieve."
          }
        },
        required: ["query"]
      }
    }
  }

  @grep %{
    type: "function",
    function: %{
      name: "keyword_search",
      description: "use grep to find relevant code snippets",
      parameters: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description: "The specific keyword or valid ripgrep regex to search for."
          }
        },
        required: ["query"]
      }
    }
  }

  defp request(query) do
    messages = [
      %{
        role: "system",
        content:
          """
          You are a helpful code retrieval planner.
          Based on the user's query and context, use one or multiple tools to retrieve relevant code snippets.
          Always use tools and do something.
          """
          |> String.trim()
      },
      %{
        role: "user",
        content: query
      }
    ]

    Req.post(
      base_url: @base_url,
      url: "/chat/completions",
      headers: [
        {"Authorization", "Bearer #{Application.fetch_env!(:langchain, :openai_key)}"},
        {"Content-Type", "application/json"}
      ],
      json: %{
        model: @model_id,
        stream: false,
        temperature: 0,
        tools: [@embedding, @grep],
        tool_choice: "auto",
        messages: messages
      }
    )
  end
end
