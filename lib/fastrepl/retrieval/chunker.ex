defmodule Fastrepl.Retrieval.Chunker.Chunk do
  defstruct file_path: "", content: "", spans: []

  def from(root, path, lines \\ []) do
    content =
      case File.read(path) do
        {:ok, content} -> content
        {:error, _} -> ""
      end

    %__MODULE__{
      file_path: Path.relative_to(path, root),
      content: content,
      spans: lines |> Enum.map(&{&1, &1})
    }
  end

  def merge(
        %__MODULE__{file_path: file_path1} = chunk1,
        %__MODULE__{file_path: file_path2} = chunk2
      )
      when file_path1 != file_path2 do
    [chunk1, chunk2]
  end

  def merge(
        %__MODULE__{file_path: file_path1} = chunk1,
        %__MODULE__{file_path: file_path2} = chunk2
      )
      when file_path1 == file_path2 do
    %__MODULE__{chunk1 | spans: merge_spans(chunk1.spans, chunk2.spans)}
  end

  defp merge_spans(spans1, spans2) do
    spans1 ++ spans2
  end
end

defimpl Jason.Encoder, for: Fastrepl.Retrieval.Chunker.Chunk do
  alias Fastrepl.Retrieval.Chunker.Chunk

  def encode(%Chunk{} = chunk, opts) do
    chunk
    |> Map.from_struct()
    |> Map.replace_lazy(:spans, fn spans -> Enum.map(spans, &Tuple.to_list/1) end)
    |> Jason.Encode.map(opts)
  end
end

defimpl String.Chars, for: Fastrepl.Retrieval.Chunker.Chunk do
  def to_string(%Fastrepl.Retrieval.Chunker.Chunk{
        file_path: file_path,
        content: content,
        spans: spans
      }) do
    spans
    |> Enum.map(fn {line_start, line_end} ->
      content_lines =
        content
        |> String.split("\n")
        |> Enum.slice(line_start - 1, line_end - line_start + 1)
        |> Enum.join("\n")

      """
      ```#{file_path}#L#{line_start}-L#{line_end}
      #{content_lines}
      ```
      """
      |> String.trim()
    end)
    |> Enum.join("\n---\n")
    |> String.trim()
  end
end

defmodule Fastrepl.Retrieval.Chunker do
  alias Fastrepl.Native.CodeUtils
  alias Fastrepl.Retrieval.Chunker.Chunk

  def version(), do: CodeUtils.chunker_version()

  def chunk_code(path, code) do
    CodeUtils.chunk_code(path, code)
  end

  def chunk_file(path) do
    code = File.read!(path)

    if String.valid?(code) do
      chunk_code(path, code)
    else
      []
    end
  end

  def dedupe(chunks) do
    dedupe(chunks, [])
  end

  defp dedupe([], acc), do: Enum.reverse(acc)

  defp dedupe([current | rest], acc) do
    acc
    |> Enum.find_index(fn %Chunk{file_path: file_path} -> file_path == current.file_path end)
    |> case do
      nil ->
        dedupe(rest, [current | acc])

      index ->
        existing = Enum.at(acc, index)

        dedupe(
          rest,
          [
            %Chunk{existing | spans: concat_tuples(existing.spans ++ current.spans)}
            | List.delete_at(acc, index)
          ]
        )
    end
  end

  defp concat_tuples(list) do
    list
    |> Enum.reduce([], fn tuple, acc -> concat_tuple(tuple, acc) end)
    |> Enum.reverse()
  end

  defp concat_tuple({a, b}, []), do: [{a, b}]

  defp concat_tuple({a, b}, [{c, d} | rest]) do
    cond do
      a <= c && b >= d -> [{a, b} | rest]
      a >= c && b <= d -> [{c, d} | rest]
      a <= d + 1 -> [{min(a, c), max(b, d)} | rest]
      true -> [{a, b}, {c, d} | rest]
    end
  end
end
