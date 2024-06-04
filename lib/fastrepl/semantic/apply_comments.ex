defmodule Fastrepl.SemanticFunction.ApplyComments do
  alias Fastrepl.FS.Repository
  alias Fastrepl.FS.Mutation
  alias Fastrepl.Sessions.Comment

  @spec run(Repository.t(), [Comment.t()]) :: [Mutation.t()]
  def run(repo, comments) do
    comments
    |> parallelize()
    |> Enum.map(&Task.async(fn -> impl(repo, &1) end))
    |> Task.await_many(15 * 1000)
    |> List.flatten()
  end

  defp parallelize(comments) do
    grouped_comments =
      comments
      |> Enum.group_by(& &1.file_path)
      |> Enum.map(fn {_path, comments} -> comments end)

    grouped_comments
    |> Enum.reduce([], fn cur, acc ->
      i = grouped_comments |> Enum.find_index(&(&1 == cur))

      past =
        grouped_comments
        |> Enum.take(i)
        |> List.flatten()

      future =
        grouped_comments
        |> Enum.drop(i + 1)
        |> List.flatten()

      acc ++ [%{past: past, present: cur, future: future}]
    end)
  end

  defp impl(repo, %{past: past, present: present, future: future}) do
    current_file_path = present |> Enum.at(0) |> Map.get(:file_path)
    current_file = repo.original_files |> Enum.find(&(&1.path == current_file_path))

    messages = [
      %{
        role: "system",
        content: """
        You are a senior software engineer with extensive experience in modifying existing codebases.
        Your job is to decide what mutations should be applied to the codebase based on the information user provided.

        The mutations must follow specific format, otherwise it will be rejected and you will be fired.
        Currently, you can only MODIFY a file. (no DELETE or CREATE)

        <mutations>
        <mutation>
        <type>MODIFY</type>
        <selected_section>
        SELECTED_SECTION
        </selected_section>
        <updated_section>
        UPDATED_SECTION
        </updated_section>
        </mutation>
        </mutations>

        A single mutation contains two parts:
        1. selected_section: single, continuous section of the file that needs to be modified.
        2. updated_section: content after mutation is applied. The change should be minimal and targeted.

        For example, let's say you got a file with the following content:

        ```
        const a = 1;
        const b = 2;
        const c = 3;
        const d = 4;
        const e = 5;
        ```

        And if you decided to modify `const b = 2;` to `const b = 3;`, and `const d = 4;` to `const d = 5;`, you should write two mutations like this:

        <mutations>
        <mutation>
        <type>MODIFY</type>
        <selected_section>
        const b = 2;
        </selected_section>
        <updated_section>
        const b = 3;
        </updated_section>
        </mutation>
        <mutation>
        <type>MODIFY</type>
        <selected_section>
        const d = 4;
        </selected_section>
        <updated_section>
        const d = 5;
        </updated_section>
        </mutation>
        </mutations>

        Often, the selected section is too large compared to the part you want to modify. For this case, you can use ... to indicate unchanged part.
        There are two IMPORTANT things to note when using `...`:
        1. `...` should be placed at the start and end of the selected section.
        2. Make sure to include more context to reduce ambiguity.

        For example, let's say you got a file with a ascending sequence of numbers, from 1 to 100.
        And if you decided to modify the section from 20 to 23 to 33 to 37, you should write:

        <mutations>
        <mutation>
        <type>MODIFY</type>
        <selected_section>
        ...
        17
        18
        19
        20
        21
        22
        23
        24
        25
        ...
        </selected_section>
        <updated_section>
        17
        18
        19
        33
        34
        35
        36
        37
        24
        25
        </updated_section>
        </mutation>
        </mutations>
        """
      },
      %{
        role: "user",
        content: """
        #{render_future_comments(future)}
        #{render_past_comments(past)}
        #{render_present_comments(current_file, present)}

        Now, think step by step and give me high-quality mutations.
        """
      }
    ]

    generation =
      Fastrepl.AI.chat(
        %{
          model: "gpt-4o",
          stream: false,
          temperature: 0,
          messages: messages
        },
        otel_attrs: %{module: __MODULE__}
      )

    case generation do
      {:ok, content} -> content |> parse_section_modified(current_file.path)
      {:error, _} -> []
    end
  end

  defp render_past_comments(comments) do
    if comments == [] do
      ""
    else
      rendered_comments =
        comments
        |> Enum.map(&to_string/1)
        |> Enum.join("\n\n")

      """
      These are comments that are already applied to the codebase.
      Use these comments as a reference. For example, your future changes should be consistent with these comments.

      <applied_comments>
      #{rendered_comments}
      </applied_comments>
      """
    end
  end

  defp render_future_comments(comments) do
    if comments == [] do
      ""
    else
      rendered_comments =
        comments
        |> Enum.map(&to_string/1)
        |> Enum.join("\n\n")

      """
      These are comments that are not yet applied to the codebase, and should not be applied this time.
      Use these comments as a reference. For example, it might be useful if you know what you will do later.

      <comments_to_apply_later>
      #{rendered_comments}
      </comments_to_apply_later>
      """
    end
  end

  defp render_present_comments(file, comments) when length(comments) > 0 do
    rendered_comments =
      comments
      |> Enum.map(fn comment ->
        selected =
          Fastrepl.String.read_lines!(file.content, {comment.line_start, comment.line_end})

        """
        <comment>
        <selected_section>
        #{selected}
        </selected_section>
        <comment_on_selected_section>
        #{comment.content}
        </comment_on_selected_section>
        </comment>
        """
      end)
      |> Enum.join("\n\n")

    """
    This is current file that you are working on.
    ```#{file.path}
    #{file.content}
    ```

    These are comments that you MUST read carefully and make changes to the codebase:

    <comments_to_apply_now>
    #{rendered_comments}
    </comments_to_apply_now>
    """
  end

  defp parse_section_modified(generated, file_path) do
    pattern =
      ~r/<mutation>.*?<type>(.*?)<\/type>.*?<selected_section>\n(.*?)\n<\/selected_section>.*?<updated_section>\n(.*?)\n<\/updated_section>.*?<\/mutation>/s

    pattern
    |> Regex.scan(generated, capture: :all_but_first)
    |> Enum.map(fn [type, selected_section, updated_section] ->
      case String.upcase(type) do
        "MODIFY" ->
          Mutation.new(:modify, %{
            target_path: file_path,
            target_section: selected_section,
            data: updated_section
          })

        _ ->
          nil
      end
    end)
    |> Enum.reject(&is_nil/1)
  end
end
