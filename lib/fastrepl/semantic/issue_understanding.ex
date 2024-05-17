defmodule Fastrepl.SemanticFunction.IssueUnderstanding do
  use Retry

  alias LangChain.Chains.LLMChain
  alias LangChain.Message

  @spec run(String.t()) :: String.t()
  def run(rendered) do
    messages = [
      Message.new_system!(
        """
        You are a senior software engineer with extensive experience in resolving issues in open source projects.
        Your resonse should be wrapped in <issue_understanding> tags, in markdown format.

        Like this:

        <issue_understanding>
        <YOUR_RESPONSE>
        </issue_understanding>
        """
        |> String.trim()
      ),
      Message.new_user!(
        """
        Please provide a concise summary of the Github issue and comments.
        The summary should be straightforward, so that anyone can start working on the issue.

        Here's the Github issue and comments. (This is scraped and parsed from the webpage.)
        #{rendered}
        """
        |> String.trim()
      )
    ]

    llm(messages)
  end

  defp llm(messages) do
    retry with: exponential_backoff() |> randomize |> cap(2_000) |> expiry(6_000) do
      LLMChain.new!(%{
        llm: Fastrepl.chat_model(%{model: "gpt-4-turbo", stream: false, temperature: 0})
      })
      |> LLMChain.add_messages(messages)
      |> LLMChain.run()
    after
      {:ok, _, %Message{} = message} -> parse_section(message.content)
    else
      error -> error
    end
  end

  defp parse_section(content) do
    pattern = ~r/<issue_understanding>\n(.*?)\n<\/issue_understanding>/s

    case Regex.run(pattern, content) do
      [_, code] -> {:ok, code}
      _ -> {:error, content}
    end
  end
end
