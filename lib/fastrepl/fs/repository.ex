defmodule Fastrepl.FS.Repository do
  defstruct root_path: nil, paths: [], original_files: [], current_files: [], config: nil

  alias __MODULE__
  alias Fastrepl.FS
  alias Fastrepl.Native.CodeUtils
  alias Fastrepl.Config

  @type t :: %Repository{
          root_path: String.t(),
          paths: [String.t()],
          original_files: [FS.File.t()],
          current_files: [FS.File.t()],
          config: Config.t() | nil
        }

  def from(repo_full_name, commit_sha, auth_token \\ nil) do
    case FS.clone(repo_full_name, commit_sha, auth_token) do
      {:ok, root_path} ->
        paths =
          root_path
          |> FS.list_files()
          |> Enum.map(&Path.relative_to(&1, root_path))

        config_path = Path.join(root_path, "fastrepl.yaml")

        repo =
          if File.exists?(config_path) do
            case config_path |> File.read!() |> Config.parse() do
              {:ok, config} -> %Repository{root_path: root_path, paths: paths, config: config}
              _ -> %Repository{root_path: root_path, paths: paths, config: %Config{}}
            end
          else
            %Repository{root_path: root_path, paths: paths, config: %Config{}}
          end

        {:ok, repo}

      {:error, error} ->
        {:error, error}
    end
  end

  def apply_patches!(%Repository{original_files: [], current_files: []} = repo, patches) do
    patches |> Enum.reduce(repo, &apply_patch!(&2, &1))
  end

  defp apply_patch!(%Repository{} = repo, %FS.Patch{status: :added, path: path, content: patch}) do
    current_files = [
      %FS.File{path: path, content: CodeUtils.apply_patch("", patch)} | repo.current_files
    ]

    %Repository{repo | current_files: current_files}
  end

  defp apply_patch!(%Repository{} = repo, %FS.Patch{status: :removed, path: path}) do
    original_files = [
      %FS.File{path: path, content: File.read!(Path.join(repo.root_path, path))}
      | repo.original_files
    ]

    %Repository{repo | original_files: original_files}
  end

  defp apply_patch!(%Repository{} = repo, %FS.Patch{status: :modified, path: path, content: patch}) do
    original_content = File.read!(Path.join(repo.root_path, path))
    modified_content = CodeUtils.apply_patch(original_content, patch)

    original_files = [%FS.File{path: path, content: original_content} | repo.original_files]
    current_files = [%FS.File{path: path, content: modified_content} | repo.current_files]

    %Repository{repo | original_files: original_files, current_files: current_files}
  end

  def add_file!(repo, file_path) do
    file = %FS.File{path: file_path, content: File.read!(Path.join(repo.root_path, file_path))}
    current_files = [file | repo.current_files]
    original_files = [file | repo.original_files]

    %Repository{repo | current_files: current_files, original_files: original_files}
  end

  def update_file(repo, file) do
    index = repo.current_files |> Enum.find_index(&(&1.path == file.path))
    existing_file = repo.current_files |> Enum.at(index)
    updated_file = %FS.File{existing_file | content: file.content}

    %Repository{repo | current_files: repo.current_files |> List.replace_at(index, updated_file)}
  end

  def find_file(repo, file_path) do
    repo.original_files
    |> Enum.find(fn file -> file.path == file_path end)
  end
end
