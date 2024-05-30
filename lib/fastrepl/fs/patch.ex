defmodule Fastrepl.FS.Patch do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.FS.File
  alias Fastrepl.FS.Repository
  alias Fastrepl.Native.CodeUtils
  alias Fastrepl.Sessions.Session

  @type t :: %Patch{
          status: :added | :modified | :removed,
          path: String.t(),
          content: String.t()
        }

  @derive {Jason.Encoder, only: [:path, :content]}
  schema "patches" do
    field :status, Ecto.Enum, values: [:added, :modified, :removed]
    field :path, :string
    field :content, :string

    belongs_to :session, Session

    timestamps(type: :utc_datetime)
  end

  def changeset(%Patch{} = patch, attrs) do
    patch
    |> cast(attrs, [:status, :path, :content, :session_id])
    |> validate_required([:status, :path, :content, :session_id])
  end

  @spec from(Repository.t()) :: [t]
  def from(%Repository{} = repo) do
    original_paths = MapSet.new(repo.original_files, & &1.path)
    current_paths = MapSet.new(repo.current_files, & &1.path)

    added =
      MapSet.difference(current_paths, original_paths)
      |> Enum.map(fn path ->
        file = repo.current_files |> Enum.find(&(&1.path == path))
        new(:added, file)
      end)

    removed =
      MapSet.difference(original_paths, current_paths)
      |> Enum.map(fn path ->
        file = repo.original_files |> Enum.find(&(&1.path == path))
        new(:removed, file)
      end)

    modifed =
      MapSet.intersection(original_paths, current_paths)
      |> Enum.map(fn path ->
        old_file = repo.original_files |> Enum.find(&(&1.path == path))
        new_file = repo.current_files |> Enum.find(&(&1.path == path))
        {old_file, new_file}
      end)
      |> Enum.filter(fn {old_file, new_file} -> old_file.content != new_file.content end)
      |> Enum.map(fn {old_file, new_file} -> new(:modified, old_file, new_file) end)

    added ++ removed ++ modifed
  end

  @spec new(:added, File.t()) :: t
  def new(:added, file) do
    patch =
      CodeUtils.create_patch(
        "/dev/null",
        Path.join("b", file.path),
        "",
        file.content
      )

    %Patch{status: :added, content: patch, path: file.path}
  end

  @spec new(:removed, File.t()) :: t
  def new(:removed, file) do
    patch =
      CodeUtils.create_patch(
        Path.join("a", file.path),
        "/dev/null",
        file.content,
        ""
      )

    %Patch{status: :removed, content: patch, path: file.path}
  end

  @spec new(:modified, File.t(), File.t()) :: t
  def new(:modified, old_file, new_file) do
    patch =
      CodeUtils.create_patch(
        Path.join("a", old_file.path),
        Path.join("b", new_file.path),
        old_file.content,
        new_file.content
      )

    %Patch{status: :modified, content: patch, path: new_file.path}
  end
end
