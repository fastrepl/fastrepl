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

  @spec from!(Path.t()) :: t()
  def from!(path) do
    %__MODULE__{
      path: path,
      content: File.read!(path)
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

defmodule Fastrepl.Repository.Comment do
  defstruct file_path: "", line_start: 0, line_end: 0, content: ""

  @type t :: %__MODULE__{
          file_path: String.t(),
          line_start: pos_integer(),
          line_end: pos_integer(),
          content: String.t()
        }
end
