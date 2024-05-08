defmodule Fastrepl.Native do
  def error(), do: :erlang.nif_error(:nif_not_loaded)
end

defmodule Fastrepl.Native.CodeUtils do
  use Rustler, otp_app: :fastrepl, crate: :code_utils
  import Fastrepl.Native, only: [error: 0]

  alias Fastrepl.Retrieval.Chunker.Chunk

  @spec chunker_version() :: pos_integer()
  def chunker_version(), do: error()

  @spec chunk_code(String.t(), String.t()) :: [Chunk.t()]
  def chunk_code(_path, _code), do: error()

  @spec grep_file(String.t(), String.t()) :: [integer()]
  def grep_file(_path, _pattern), do: error()
end

defmodule Fastrepl.Native.GitUtils do
  use Rustler, otp_app: :fastrepl, crate: :git_utils
  import Fastrepl.Native, only: [error: 0]

  @spec clone(String.t(), String.t(), pos_integer()) :: boolean()
  def clone(_repo_url, _dest_path, _depth), do: error()

  @spec patch(String.t()) :: String.t()
  def patch(_repo_root_path), do: error()

  @spec patches(String.t()) :: [String.t()]
  def patches(_repo_root_path), do: error()

  @spec commits(String.t()) :: map()
  def commits(_repo_root_path), do: error()
end
