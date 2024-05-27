defmodule Fastrepl.SemanticFunction.Modify do
  alias Fastrepl.FS.Repository
  alias Fastrepl.FS.Mutation
  alias Fastrepl.Sessions.Comment

  @spec run(Repository.t(), Comment.t()) :: {:ok, Mutation.t()} | {:error, any()}
  def run(repo, comment) do
    file = repo.current_files |> Enum.find(&(&1.path == comment.file_path))
    target = Fastrepl.String.read_lines!(file.content, {comment.line_start, comment.line_end})

    messages = [
      %{
        role: "system",
        content: """
        You are a senior software engineer with extensive experience in modifying existing codebases.

        The user will provide you with a file and comments about the file.
        Finally, the user will provide you a section of the file that needs to be modified.

        This has a specific format. For example:
        #{section_to_modify_example()}

        You should think step by step and respond with the modified section.

        For example:
        #{section_modified_example()}
        """
      },
      %{
        role: "user",
        content: """
        Here's the file:

        ```#{file.path}
        #{file.content}
        ```

        Here's the section that needs to be modified:

        #{section_to_modify(target, comment.content)}
        """
      }
    ]

    case llm(messages) do
      {:ok, content} ->
        mut =
          Mutation.new(:modify, %{target_path: file.path, target_section: target, data: content})

        {:ok, mut}

      {:error, message} ->
        {:error, message}
    end
  end

  @spec run!(Repository.t(), Comment.t()) :: Mutation.t()
  def run!(repo, comment) do
    {:ok, mut} = run(repo, comment)
    mut
  end

  defp llm(messages) do
    result =
      Fastrepl.AI.chat(
        %{
          model: "gpt-4-turbo",
          stream: false,
          temperature: 0,
          messages: messages
        },
        otel_attrs: %{module: __MODULE__}
      )

    case result do
      {:ok, content} -> parse_section_modified(content)
      error -> error
    end
  end

  defp section_to_modify(content, instruction) do
    """
    <section_to_modify>
    <content>
    #{content}
    </content>
    <instruction>
    #{instruction}
    </instruction>
    </section_to_modify>
    """
    |> String.trim()
  end

  defp section_modified(content) do
    """
    <section_modified>
    <content>
    #{content}
    </content>
    </section_modified>
    """
    |> String.trim()
  end

  def section_to_modify_example() do
    content =
      """
      const a = () => {
        console.log("Hello");
      };
      """

    instruction =
      """
      instead of console log in the function, raise an error.
      """

    section_to_modify(String.trim(content), String.trim(instruction))
  end

  def section_modified_example() do
    content =
      """
      const a = () => {
        throw new Error("Hello");
      };
      """

    section_modified(String.trim(content))
  end

  defp parse_section_modified(content) do
    pattern = ~r/<section_modified>.*?<content>\n(.*?)\n<\/content>.*?<\/section_modified>/s

    case Regex.run(pattern, content) do
      [_, code] -> {:ok, code}
      _ -> {:error, content}
    end
  end
end
