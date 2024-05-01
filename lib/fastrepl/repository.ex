defmodule Fastrepl.Repository do
  defstruct [:full_name, :sha, :root_path, :vectordb_pid, :indexing_progress, :indexing_total]

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
