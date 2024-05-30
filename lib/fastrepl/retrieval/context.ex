defmodule Fastrepl.Retrieval.Context do
  defstruct repo_root_path: nil, paths: [], chunks: [], tools: [], tree: nil

  alias __MODULE__
  alias Fastrepl.FS
  alias Fastrepl.Retrieval.Chunker
  alias Fastrepl.Retrieval.Chunker.Chunk

  @type t :: %__MODULE__{
          repo_root_path: String.t(),
          paths: [String.t()],
          chunks: [Chunk.t()],
          tools: [module()],
          tree: String.t()
        }

  def from(repo_root_path) do
    absoulte_paths = repo_root_path |> FS.list_informative_files()
    relative_paths = absoulte_paths |> Enum.map(&Path.relative_to(&1, repo_root_path))

    chunks =
      absoulte_paths
      |> Stream.map(fn path ->
        case File.read(path) do
          {:ok, content} -> {Path.relative_to(path, repo_root_path), content}
          _ -> nil
        end
      end)
      |> Stream.reject(&is_nil/1)
      |> Stream.flat_map(fn {path, content} -> Chunker.chunk_code(path, content) end)
      |> Enum.to_list()

    tree =
      relative_paths
      |> FS.Tree.build()
      |> FS.Tree.render()

    %Context{
      repo_root_path: repo_root_path,
      paths: relative_paths,
      chunks: chunks,
      tree: tree
    }
  end

  def add_tool(ctx, tool) do
    %Context{ctx | tools: [tool | ctx.tools]}
  end

  def add_tools(ctx, tools) do
    tools |> Enum.reduce(ctx, &add_tool(&2, &1))
  end
end
