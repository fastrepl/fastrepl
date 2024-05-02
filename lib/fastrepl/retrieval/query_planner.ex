defmodule Fastrepl.Retrieval.QueryPlanner do
  @base_url "https://api.openai.com/v1"
  @model_id "gpt-4-turbo-2024-04-09"

  use Retry

  alias Fastrepl.LLM

  @spec from_query(String.t()) :: {:ok, [{String.t(), map()}]}
  def from_query(chat) do
    messages = [
      %{
        role: "system",
        content:
          """
          You are a helpful code retrieval planner.
          Based on the user's query and context, use tools to retrieve relevant code snippets.
          Use as many tools as needed.
          """
          |> String.trim()
      },
      %{
        role: "user",
        content: chat |> String.trim()
      }
    ]

    request(messages)
  end

  @spec from_issue(GitHub.Issue.t(), [GitHub.Issue.Comment.t()]) :: {:ok, [{String.t(), map()}]}
  def from_issue(issue, comments \\ []) do
    messages = [
      %{
        role: "system",
        content:
          """
          You are a helpful code retrieval planner.
          When user provides a github issue, use tools to retrieve code snippets that are useful to understand or solve the issue.
          Use as many tools as needed.
          """
          |> String.trim()
      },
      %{
        role: "user",
        content:
          """
          This is a github issue to be solved:

          #{LLM.render(issue)}
          ---

          #{comments |> Enum.map(&LLM.render/1) |> Enum.join("\n")}
          """
          |> String.trim()
      }
    ]

    request(messages)
  end

  @path %{
    type: "function",
    function: %{
      name: "search_file_path",
      description: "search files with path",
      parameters: %{
        type: "object",
        properties: %{
          query: %{
            type: "string",
            description:
              "Exact filename, path, or partial keyword that might be included in the file path."
          }
        },
        required: ["query"]
      }
    }
  }

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
            description:
              "This is not filename or path, but keyword or valid ripgrep regex that might be included in the code snippets."
          }
        },
        required: ["query"]
      }
    }
  }

  defp request(messages) do
    retry with:
            exponential_backoff()
            |> randomize
            |> cap(1_000)
            |> expiry(4_000) do
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
          tools: [@path, @embedding, @grep],
          tool_choice: "auto",
          messages: messages
        }
      )
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
      error -> []
    end
  end
end
