defmodule Fastrepl.Retrieval.Result do
  defstruct [:file_path, :file_content, :spans]

  alias __MODULE__
  alias Fastrepl.Retrieval.Chunker.Chunk

  @type t :: %Result{
          # absolute path
          file_path: String.t(),
          file_content: String.t(),
          spans: [{pos_integer(), pos_integer()}]
        }

  @buffer_size 10

  def from!(%Chunk{file_path: file_path, span: {line_start, line_end}}) do
    file_content = File.read!(file_path)
    max_line = file_content |> String.split("\n") |> length

    %Result{
      file_path: file_path,
      file_content: file_content,
      spans: [{max(1, line_start - @buffer_size), min(line_end + @buffer_size, max_line)}]
    }
  end

  def from!(path) do
    file_content = File.read!(path)
    max_line = file_content |> String.split("\n") |> length

    %Result{
      file_path: path,
      file_content: file_content,
      spans: [{1, max_line}]
    }
  end

  def from!(path, lines) do
    file_content = File.read!(path)
    max_line = file_content |> String.split("\n") |> length

    %Result{
      file_path: path,
      file_content: file_content,
      spans: lines |> Enum.map(&{max(1, &1 - @buffer_size), min(&1 + @buffer_size, max_line)})
    }
  end

  def fuse(results, options) when is_list(results) do
    results
    |> Enum.reduce([], fn %{file_path: file_path, spans: spans} = result, acc ->
      case acc do
        [%{file_path: ^file_path, spans: existing_spans} = head | tail] ->
          [%{head | spans: existing_spans ++ spans} | tail]

        _ ->
          [result | acc]
      end
    end)
    |> Enum.reverse()
    |> Enum.map(&fuse(&1, options))
  end

  def fuse(%Result{spans: spans} = result, options) do
    spans = spans |> Enum.sort_by(fn {start, _end} -> start end)
    %Result{result | spans: fuse(spans, [], options)}
  end

  defp fuse([current | rest], [], options), do: fuse(rest, [current], options)
  defp fuse([], acc, _), do: Enum.reverse(acc)

  defp fuse([{current_start, current_end} | rest], [{prev_start, prev_end} | _] = prev, options) do
    min_distance = Keyword.get(options, :min_distance, 20)

    if current_start - prev_end <= min_distance do
      updated_prev = [{prev_start, max(prev_end, current_end)} | Enum.drop(prev, 1)]
      fuse(rest, updated_prev, options)
    else
      fuse(rest, [{current_start, current_end} | prev], options)
    end
  end
end

defimpl String.Chars, for: Fastrepl.Retrieval.Result do
  def to_string(%Fastrepl.Retrieval.Result{} = result) do
    lines = result.file_content |> String.split("\n")

    snippets =
      result.spans
      |> Enum.map(fn {line_start, line_end} ->
        lines
        |> Enum.slice(line_start - 1, line_end - line_start + 1)
        |> Enum.join("\n")
      end)

    """
    ```#{result.file_path}
    #{snippets |> Enum.join("\n...\n")}
    ```
    """
    |> String.trim()
  end
end
