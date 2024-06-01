defmodule Fastrepl.FS.Mutation do
  defstruct [:type, :target_path, :target_section, :data]
  import Kernel, except: [apply: 2]

  alias __MODULE__
  alias Fastrepl.FS
  alias Fastrepl.Retrieval.CodeBlock

  @type t :: %Mutation{
          type: :add | :modify | :remove,
          target_path: String.t(),
          target_section: String.t() | nil,
          data: String.t() | nil
        }

  def new(:add, %{target_path: target_path, data: data}) do
    %Mutation{type: :add, target_path: target_path, data: data}
  end

  def new(:remove, %{target_path: target_path}) do
    %Mutation{type: :remove, target_path: target_path}
  end

  def new(:modify, %{target_path: target_path, target_section: target_section, data: data}) do
    %Mutation{type: :modify, target_path: target_path, target_section: target_section, data: data}
  end

  def apply(%FS.Repository{} = repo, mutations) when is_list(mutations) do
    repo = %FS.Repository{repo | current_files: repo.original_files}
    mutations |> Enum.reduce(repo, fn mut, acc -> apply(acc, mut) end)
  end

  def apply(%FS.Repository{} = repo, %Mutation{type: :add} = mutation) do
    new_file = %FS.File{path: mutation.target_path, content: mutation.data}
    %FS.Repository{repo | current_files: [new_file | repo.current_files]}
  end

  def apply(%FS.Repository{} = repo, %Mutation{type: :remove} = mutation) do
    current_files = repo.current_files |> Enum.reject(&(&1.path == mutation.target_path))
    %FS.Repository{repo | current_files: current_files}
  end

  def apply(%FS.Repository{} = repo, %Mutation{type: :modify} = mutation) do
    file_index = Enum.find_index(repo.current_files, &(&1.path == mutation.target_path))
    file = repo.current_files |> Enum.at(file_index)

    {line_start, line_end} = CodeBlock.find(mutation.target_section, file.content)

    lines = String.split(file.content, "\n")

    left =
      lines
      |> Enum.slice(0, line_start - 1)
      |> Enum.join("\n")

    right =
      lines
      |> Enum.slice(line_end - 1, length(lines) - line_end + 1)
      |> Enum.join("\n")

    content =
      [left, mutation.data, right]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join("\n")

    current_files =
      repo.current_files
      |> List.replace_at(file_index, %FS.File{file | content: content})

    %FS.Repository{repo | current_files: current_files}
  end
end
