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
    informative_files = FS.list_informative_files(repo_root_path)

    tree =
      informative_files
      |> Enum.map(&Path.relative_to(&1, repo_root_path))
      |> FS.Tree.build()
      |> FS.Tree.render()

    paths =
      informative_files
      |> Enum.map(&Path.relative_to(&1, repo_root_path))

    chunks =
      informative_files
      |> Enum.flat_map(&Chunker.chunk_file/1)

    %Context{repo_root_path: repo_root_path, paths: paths, chunks: chunks, tree: tree}
  end

  def add_tool(ctx, tool) do
    %Context{ctx | tools: [tool | ctx.tools]}
  end

  def add_tools(ctx, tools) do
    tools |> Enum.reduce(ctx, &add_tool(&2, &1))
  end
end
