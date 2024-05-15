defmodule Fastrepl.Retrieval.Chunker.Chunk do
  defstruct [:file_path, :content, :span]

  @type t :: %__MODULE__{
          file_path: String.t(),
          content: String.t(),
          span: {pos_integer(), pos_integer()}
        }

  def from!(path, {line_start, line_end}) do
    content =
      File.read!(path)
      |> String.split("\n")
      |> Enum.slice(line_start - 1, line_end - line_start + 1)
      |> Enum.join("\n")

    %__MODULE__{
      file_path: path,
      content: content,
      span: {line_start, line_end}
    }
  end
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
