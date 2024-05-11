defmodule Fastrepl.Repository.File do
  @moduledoc """
  Every Mutation will be applied to a File, not to a actual file on disk.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias Fastrepl.Repository

  @type t :: %Repository.File{}

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    field :content, :string
    field :path, :string
  end

  @spec new(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %Repository.File{}
    |> cast(attrs, [:content, :path])
    |> validate_required([:content, :path])
    |> apply_action(:insert)
  end

  @spec new!(attrs :: map()) :: t
  def new!(attrs \\ %{}) do
    {:ok, file} = new(attrs)
    file
  end

  @spec from(Repository.t(), String.t()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def from(repo, path) do
    absoulte_path = Path.join(repo.root_path, path)

    case File.read(absoulte_path) do
      {:ok, content} -> new(%{path: path, content: content})
      _ -> new(%{path: path})
    end
  end

  @spec from!(Repository.t(), String.t()) :: t
  def from!(repo, path) do
    {:ok, file} = from(repo, path)
    file
  end

  @spec replace(t(), pos_integer(), pos_integer(), [String.t()]) :: {:ok, t()} | {:error, any()}
  def replace(file, line_start, line_end, new_lines) do
    existing_lines = file.content |> String.split("\n")

    left = existing_lines |> Enum.slice(0, line_start - 1)
    right = existing_lines |> Enum.slice(line_end - 1, length(existing_lines) - line_end + 1)

    file
    |> change(%{content: Enum.join(left ++ new_lines ++ right, "\n")})
    |> apply_action(:update)
  end

  @spec replace!(t(), pos_integer(), pos_integer(), [String.t()]) :: t
  def replace!(file, line_start, line_end, new_lines) do
    {:ok, file} = replace(file, line_start, line_end, new_lines)
    file
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
