defmodule Fastrepl.Repository do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @type t :: %Repository{}

  @primary_key false
  embedded_schema do
    field :full_name, :string, default: ""
    field :description, :string
    field :sha, :string
    field :root_path, :string
    field :paths, {:array, :string}, default: []
    field :original_files, {:array, :any}, default: []
    field :current_files, {:array, :any}, default: []
    field :comments, {:array, :any}, default: []
    field :diffs, {:array, :any}, default: []
    field :chunks, {:array, :any}, default: []
  end

  def new(attrs \\ %{}) do
    %Repository{}
    |> cast(attrs, [
      :full_name,
      :description,
      :sha,
      :root_path,
      :paths,
      :original_files,
      :current_files,
      :comments,
      :diffs
    ])
    # |> validate_required([:full_name, :description, :sha, :root_path])
    |> apply_action(:insert)
  end

  def new!(attrs \\ %{}) do
    {:ok, repo} = new(attrs)
    repo
  end

  @spec add_file(t(), Repository.File.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def add_file(repo, file) do
    repo
    |> change()
    |> validate_file_not_added(file.path)
    |> then(fn changeset ->
      changeset
      |> put_change(:original_files, [file | get_field(changeset, :original_files)])
      |> put_change(:current_files, [file | get_field(changeset, :current_files)])
    end)
    |> apply_action(:update)
  end

  @spec add_file!(t(), Repository.File.t()) :: t()
  def add_file!(repo, path) do
    {:ok, repo} = add_file(repo, path)
    repo
  end

  @spec replace_file(t(), Repository.File.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def replace_file(repo, file) do
    repo
    |> change()
    |> validate_file_exists(file.path)
    |> then(fn changeset ->
      files = changeset |> get_field(:current_files)
      index = files |> Enum.find_index(&(&1.path == file.path))
      changeset |> change(current_files: files |> List.replace_at(index, file))
    end)
    |> apply_action(:update)
  end

  @spec create_file(t(), Repository.File.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def create_file(repo, file) do
    repo
    |> change()
    |> validate_file_not_exists(file.path)
    |> then(fn changeset ->
      files = [file | changeset |> get_field(:current_files)]
      changeset |> change(current_files: files)
    end)
    |> apply_action(:update)
  end

  @spec create_file!(t(), Repository.File.t()) :: t()
  def create_file!(repo, file) do
    {:ok, repo} = create_file(repo, file)
    repo
  end

  @spec delete_file(t(), String.t()) :: {:ok, t()} | {:error, Ecto.Changeset.t()}
  def delete_file(repo, path) do
    repo
    |> change()
    |> validate_file_exists(path)
    |> then(fn changeset ->
      files = changeset |> get_field(:current_files) |> Enum.reject(&(&1.path == path))
      changeset |> change(current_files: files)
    end)
    |> apply_action(:update)
  end

  @spec delete_file!(t(), String.t()) :: t()
  def delete_file!(repo, path) do
    {:ok, repo} = delete_file(repo, path)
    repo
  end

  defp validate_file_exists(%Ecto.Changeset{} = changeset, path) do
    if changeset |> get_field(:current_files) |> Enum.any?(&(&1.path == path)) do
      changeset
    else
      add_error(changeset, :path, "not exist")
    end
  end

  defp validate_file_not_exists(changeset, path) do
    if changeset |> get_field(:current_files) |> Enum.any?(&(&1.path == path)) do
      add_error(changeset, :path, "already exists")
    else
      changeset
    end
  end

  defp validate_file_not_added(changeset, path) do
    if changeset |> get_field(:original_files) |> Enum.any?(&(&1.path == path)) or
         changeset |> get_field(:current_files) |> Enum.any?(&(&1.path == path)) do
      add_error(changeset, :path, "already added")
    else
      changeset
    end
  end
end
