defmodule Fastrepl.Repository do
  alias Fastrepl.Repository
  alias Fastrepl.Retrieval.Chunker.Chunk

  defstruct full_name: "",
            description: "",
            sha: "",
            root_path: "",
            paths: [],
            chunks: [],
            files: [],
            comments: [],
            diffs: [],
            vectordb_pid: nil,
            indexing_progress: nil,
            indexing_total: nil

  @type t :: %__MODULE__{
          full_name: String.t(),
          description: String.t(),
          sha: String.t(),
          paths: [String.t()],
          root_path: String.t(),
          chunks: [Chunk.t()],
          files: [Repository.File.t()],
          comments: [Repository.Comment.t()],
          diffs: [String.t()],
          vectordb_pid: pid() | nil,
          indexing_progress: integer() | nil,
          indexing_total: integer() | nil
        }

  alias Fastrepl.Retrieval.Vectordb

  def clean_up(%__MODULE__{} = repo) do
    if repo.vectordb_pid do
      Vectordb.stop(repo.vectordb_pid)
    end

    if repo.root_path do
      File.rm_rf(repo.root_path)
    end
  end
end

defmodule Fastrepl.Repository.Mutation do
  @callback apply(Fastrepl.Repository.t()) :: Fastrepl.Repository.t()
end
