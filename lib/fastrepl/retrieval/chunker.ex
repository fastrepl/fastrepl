defmodule Fastrepl.Retrieval.Chunker.Chunk do
  defstruct [:file_path, :content, :span]

  alias __MODULE__

  @type t :: %Chunk{
          file_path: String.t(),
          content: String.t(),
          span: {pos_integer(), pos_integer()}
        }
end

defimpl String.Chars, for: Fastrepl.Retrieval.Chunker.Chunk do
  alias Fastrepl.Retrieval.Chunker.Chunk

  def to_string(%Chunk{} = chunk) do
    """
    ```#{chunk.file_path}
    #{chunk.content}
    ```
    """
    |> String.trim()
  end
end

defmodule Fastrepl.Retrieval.Chunker do
  alias Fastrepl.Native.CodeUtils

  def version(), do: CodeUtils.chunker_version()

  def chunk_code(path, code) do
    if String.valid?(code) do
      CodeUtils.chunk_code(path, code)
    else
      []
    end
  end

  def chunk_file!(path) do
    chunk_code(path, File.read!(path))
  end
end
