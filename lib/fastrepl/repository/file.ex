defmodule Fastrepl.Repository.File do
  defstruct path: "", content: ""

  alias Fastrepl.Retrieval.Chunker.Chunk

  @type t :: %__MODULE__{
          path: String.t(),
          content: String.t()
        }

  @spec from(Chunk.t()) :: t()
  def from(chunk) do
    %__MODULE__{
      path: chunk.file_path,
      content: chunk.content
    }
  end

  @spec from!(Path.t()) :: t()
  def from!(path) do
    %__MODULE__{
      path: path,
      content: File.read!(path)
    }
  end
end

defmodule Fastrepl.Repository.Comment do
  defstruct file_path: "", line_start: 0, line_end: 0, content: ""

  @type t :: %__MODULE__{
          file_path: String.t(),
          line_start: pos_integer(),
          line_end: pos_integer(),
          content: String.t()
        }
end
