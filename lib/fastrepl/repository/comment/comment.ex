defmodule Fastrepl.Repository.Comment do
  @moduledoc """
  Comment contains information or instruction about a specific part of a file.
  Eventually, it will be used to create a list of Mutations.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.Repository
  alias Fastrepl.Retrieval.CodeBlock

  use Retry

  alias LangChain.Chains.LLMChain
  alias LangChain.Message

  @type t :: %Comment{}

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    # relative path
    field :file_path, :string
    field :line_start, :integer
    field :line_end, :integer
    field :content, :string
  end

  @spec new(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %Comment{}
    |> cast(attrs, [:file_path, :line_start, :line_end, :content])
    |> validate_required([:file_path, :line_start, :line_end, :content])
    |> validate_comment()
    |> apply_action(:insert)
  end

  defp validate_comment(changeset) do
    line_start = changeset |> get_field(:line_start)
    line_end = changeset |> get_field(:line_end)

    cond do
      line_start < 1 ->
        add_error(changeset, :line_start, "should be greater than 0")

      line_start >= line_end ->
        add_error(changeset, :line_end, "should be greater than line start")

      true ->
        changeset
    end
  end

  @spec from(String.t(), [Repository.File.t()]) ::
          {:ok, [Repository.Comment.t()]} | {:error, any()}
  def from(goal, files) when is_binary(goal) and files != [] do
    case llm(messages(goal, files)) do
      {:ok, comments} ->
        comments =
          for comment <- comments,
              %{
                type: "modify",
                target_filepath: target_filepath,
                target_section: target_section,
                comment_content: comment_content
              } = comment do
            with file when not is_nil(file) <- Enum.find(files, &(&1.path == target_filepath)),
                 span when not is_nil(span) <- CodeBlock.find(target_section, file.content) do
              %Repository.Comment{
                file_path: target_filepath,
                line_start: elem(span, 0),
                line_end: elem(span, 1),
                content: comment_content
              }
            else
              _ -> nil
            end
          end
          |> Enum.reject(&is_nil/1)

        {:ok, comments}

      {:error, completion} ->
        {:error, completion}
    end
  end

  defp llm(messages) do
    retry with: exponential_backoff() |> randomize |> cap(2_000) |> expiry(6_000) do
      LLMChain.new!(%{
        llm: Fastrepl.chat_model(%{model: "gpt-4o", stream: false, temperature: 0})
      })
      |> LLMChain.add_messages(messages)
      |> LLMChain.run()
    after
      {:ok, _, %Message{} = message} -> parse_comment(message.content)
    else
      error -> error
    end
  end

  defp messages(goal, files) do
    [
      Message.new_system!(
        """
        You are senior software engineer with wide experience in guiding and mentoring developers.

        The user will provide you with a file, and a goal to achieve.(for example, simple instructions or Github issue)
        You should think step by step and respond with comments. This can be one, multiple, or none.

        Each comment must comply with the specific format. For example:
        #{modify_comment_example()}
        """
        |> String.trim()
      ),
      Message.new_user!(
        """
        This is my goal:
        ---
        #{goal}
        ---

        This is the list of files:
        ---
        #{files |> Enum.map(&to_string/1) |> Enum.join("\n\n")}
        ---
        """
        |> String.trim()
      )
    ]
  end

  defp modify_comment(target_filepath, target_section, comment_content) do
    """
    <comment>
    <type>modify</type>
    <target_filepath>#{target_filepath}</target_filepath>
    <target_section>
    #{target_section}
    </target_section>
    <comment_content>
    #{comment_content}
    </comment_content>
    </comment>
    """
    |> String.trim()
  end

  defp modify_comment_example() do
    target_filepath = "file/to/modify.js"

    target_section =
      """
      function hello() {
        let text = "hello";
        ...
        text = "world";
        return text;
      }
      """
      |> String.trim()

    comment_content =
      """
      Remove the console.log.
      """
      |> String.trim()

    modify_comment(target_filepath, target_section, comment_content)
  end

  defp parse_comment(text) do
    pattern =
      ~r/<comment>\s*<type>modify<\/type>\s*<target_filepath>\s*(.*?)\s*<\/target_filepath>\s*<target_section>\s*(.*?)\s*<\/target_section>\s*<comment_content>\s*(.*?)\s*<\/comment_content>\s*<\/comment>/s

    case Regex.scan(pattern, text) do
      [] ->
        {:error, text}

      matches ->
        comments =
          matches
          |> Enum.map(fn [_, target_filepath, target_section, comment_content] ->
            %{
              type: "modify",
              target_filepath: target_filepath,
              target_section: target_section,
              comment_content: comment_content
            }
          end)

        {:ok, comments}
    end
  end
end
