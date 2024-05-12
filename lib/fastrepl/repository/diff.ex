defmodule Fastrepl.Repository.Diff do
  @moduledoc """
  Diff is a only way to communicate with the user about the changes made to the repository.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.Repository
  alias Fastrepl.Native.CodeUtils

  @type t :: %Diff{}

  @primary_key false
  embedded_schema do
    field :mode, Ecto.Enum, values: [:edit, :create, :delete]
    field :old_path, :string
    field :new_path, :string
    field :old_content, :string
    field :new_content, :string
  end

  @spec from(Repository.t()) :: [t()]
  def from(repo) do
    original_files = MapSet.new(repo.original_files, & &1.path)
    current_files = MapSet.new(repo.current_files, & &1.path)

    deletes =
      MapSet.difference(original_files, current_files)
      |> Enum.map(&new_delete(%{old_path: &1}))

    creates =
      MapSet.difference(current_files, original_files)
      |> Enum.map(fn path ->
        file = repo.current_files |> Enum.find(&(&1.path == path))
        new_create(%{new_path: file.path, new_content: file.content})
      end)

    edits =
      MapSet.intersection(original_files, current_files)
      |> Enum.map(fn path ->
        old_file = repo.original_files |> Enum.find(&(&1.path == path))
        new_file = repo.current_files |> Enum.find(&(&1.path == path))
        {old_file, new_file}
      end)
      |> Enum.filter(fn {old_file, new_file} -> old_file.content != new_file.content end)
      |> Enum.map(fn {old_file, new_file} ->
        new_edit(%{
          old_path: old_file.path,
          old_content: old_file.content,
          new_path: new_file.path,
          new_content: new_file.content
        })
      end)

    results = deletes ++ creates ++ edits

    {oks, errors} =
      results
      |> Enum.split_with(fn
        {:ok, _} -> true
        {:error, _} -> false
      end)

    errors
    |> Enum.each(fn {:error, changeset} -> IO.inspect(changeset) end)

    oks
    |> Enum.map(fn {:ok, diff} -> diff end)
  end

  @spec new_edit(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new_edit(attrs \\ %{}) do
    %Diff{mode: :edit}
    |> cast(attrs, [:old_path, :new_path, :old_content, :new_content])
    |> validate_required([:old_path, :new_path, :old_content, :new_content])
    |> apply_action(:insert)
  end

  @spec new_create(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new_create(attrs \\ %{}) do
    %Diff{mode: :create}
    |> cast(attrs, [:new_path, :new_content])
    |> validate_required([:new_path, :new_content])
    |> apply_action(:insert)
  end

  @spec new_delete(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new_delete(attrs \\ %{}) do
    %Diff{mode: :delete}
    |> cast(attrs, [:old_path])
    |> validate_required([:old_path])
    |> apply_action(:insert)
  end

  @spec to_patch(Diff.t()) :: String.t()
  def to_patch(%Diff{mode: :edit} = diff) do
    CodeUtils.unified_diff(
      Path.join("a", diff.old_path),
      Path.join("b", diff.new_path),
      diff.old_content,
      diff.new_content
    )
  end

  def to_patch(%Diff{mode: :create} = diff) do
    CodeUtils.unified_diff(
      "/dev/null",
      Path.join("b", diff.new_path),
      "",
      diff.new_content
    )
  end

  def to_patch(%Diff{mode: :delete} = diff) do
    CodeUtils.unified_diff(
      Path.join("a", diff.old_path),
      "/dev/null",
      diff.old_content,
      ""
    )
  end
end
