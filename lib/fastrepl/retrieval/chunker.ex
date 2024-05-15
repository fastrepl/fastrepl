defmodule Fastrepl.Retrieval.Chunker.Chunk do
  defstruct [:file_path, :content, :span]

  alias __MODULE__

  @type t :: %Chunk{
          # absolute path
          file_path: String.t(),
          content: String.t(),
          span: {pos_integer(), pos_integer()}
        }
end

defimpl String.Chars, for: Fastrepl.Retrieval.Chunker.Chunk do
  alias Fastrepl.Retrieval.Chunker.Chunk

  def to_string(%Chunk{} = chunk) do
    chunk.content
  end
end

defmodule Fastrepl.Retrieval.Chunker do
  alias Fastrepl.Native.CodeUtils

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
end
