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
  alias Fastrepl.Native.RustChunker

  def chunk_code(path, code) do
    RustChunker.chunk_code(path, code)
  end

  def chunk_file(path) do
    code = File.read!(path)

    if String.valid?(code) do
      RustChunker.chunk_code(path, code)
    else
      []
    end
  end
end
