defmodule Fastrepl.FS.Repository do
  defstruct root_path: nil, paths: [], original_files: [], current_files: []

  alias __MODULE__
  alias Fastrepl.FS

  @type t :: %Repository{
          root_path: String.t(),
          paths: [String.t()],
          original_files: [FS.File.t()],
          current_files: [FS.File.t()]
        }

  alias Fastrepl.FS

  def from(repo_full_name, commit_sha, auth_token \\ nil) do
    case FS.clone(repo_full_name, commit_sha, auth_token) do
      {:ok, root_path} ->
        paths =
          root_path
          |> FS.list_files()
          |> Enum.map(&Path.relative_to(&1, root_path))

        {:ok, %Repository{root_path: root_path, paths: paths}}

      {:error, error} ->
        {:error, error}
    end
  end

  def add_file!(repo, file_path) do
    file = %FS.File{path: file_path, content: File.read!(Path.join(repo.root_path, file_path))}
    current_files = [file | repo.current_files]
    original_files = [file | repo.original_files]

    {
      %Repository{repo | current_files: current_files, original_files: original_files},
      file
    }
  end
end
