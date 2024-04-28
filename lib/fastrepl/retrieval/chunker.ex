defmodule Fastrepl.Retrieval.Chunker.Chunk do
  defstruct file_path: "", content: "", spans: []

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
end
