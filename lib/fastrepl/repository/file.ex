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

  @spec replace(t(), pos_integer(), pos_integer(), [String.t()]) :: t()
  def replace(%__MODULE__{} = file, line_start, line_end, new_lines) do
    existing_lines = file.content |> String.split("\n")

    left = existing_lines |> Enum.slice(0, line_start - 1)
    right = existing_lines |> Enum.slice(line_end - 1, length(existing_lines) - line_end + 1)

    %__MODULE__{file | content: Enum.join(left ++ new_lines ++ right, "\n")}
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
