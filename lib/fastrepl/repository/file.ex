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

  @spec find_line(t(), String.t()) :: pos_integer() | nil
  def find_line(file, pattern) do
    file_lines = String.split(file.content, "\n")
    pattern_lines = String.split(pattern, "\n")
    pattern_lines_count = length(pattern_lines)

    file_lines
    |> Enum.with_index(1)
    |> Enum.map(fn {_, index} ->
      if index + pattern_lines_count - 1 <= length(file_lines) do
        from_file = Enum.slice(file_lines, index - 1, pattern_lines_count) |> Enum.join("\n")
        {index, String.jaro_distance(from_file, pattern)}
      else
        {index, -1}
      end
    end)
    |> Enum.max_by(fn {_, similarity} -> similarity end)
    |> case do
      {index, score} when score > 0.8 -> index
      _ -> nil
    end
  end
end
