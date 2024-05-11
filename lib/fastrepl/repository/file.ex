defmodule Fastrepl.Repository.File do
  @derive Jason.Encoder
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

  @spec from!(Path.t(), Path.t()) :: t()
  def from!(root_path, file_path) do
    %__MODULE__{
      path: file_path,
      content: File.read!(Path.join(root_path, file_path))
    }
  end
end

defimpl String.Chars, for: Fastrepl.Repository.File do
  def to_string(%Fastrepl.Repository.File{} = file) do
    """
    ```#{file.path}
    #{file.content}
    ```
    """
    |> String.trim()
  end
end
