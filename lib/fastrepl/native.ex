defmodule Fastrepl.Native.CodeUtils do
  use Rustler, otp_app: :fastrepl, crate: :code_utils
  alias Fastrepl.Retrieval.Chunker.Chunk

  @spec chunker_version() :: pos_integer()
  def chunker_version(), do: error()

  @spec chunk_code(String.t(), String.t()) :: [Chunk.t()]
  def chunk_code(_path, _code), do: error()

  @spec grep_file(String.t(), String.t()) :: [integer()]
  def grep_file(_path, _pattern), do: error()

  @spec clone_depth(String.t(), String.t(), pos_integer()) :: boolean()
  def clone_depth(_repo_url, _dest_path, _depth), do: error()

  @spec clone_commit(String.t(), String.t(), String.t()) :: boolean()
  def clone_commit(_repo_url, _dest_path, _commit_hash), do: error()

  @spec commits(String.t()) :: map()
  def commits(_repo_root_path), do: error()

  @spec create_patch(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def create_patch(_old_path, _new_path, _old_content, _new_content), do: error()

  @spec apply_patch(String.t(), String.t()) :: String.t()
  def apply_patch(_base_content, _patch_content), do: error()

  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
