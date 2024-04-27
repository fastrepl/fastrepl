defmodule Fastrepl.Retrieval.Chunker.Chunk do
  defstruct file_path: "", content: "", line_start: 1, line_end: 1
end

defimpl String.Chars, for: Fastrepl.Retrieval.Chunker.Chunk do
  def to_string(%Fastrepl.Retrieval.Chunker.Chunk{
        file_path: file_path,
        content: content,
        line_start: line_start,
        line_end: line_end
      }) do
    """
    ```#{file_path}#L#{line_start}-L#{line_end}
    #{content}
    ```
    """
    |> String.trim()
  end
end

defmodule Fastrepl.Retrieval.Chunker do
  alias Fastrepl.Native.CodeUtils

  def chunk_file(path) do
    CodeUtils.chunk_file(path)
  end
end
