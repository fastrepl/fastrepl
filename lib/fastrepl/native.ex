defmodule Fastrepl.Native.CodeUtils do
  use Rustler, otp_app: :fastrepl, crate: :code_utils
  alias Fastrepl.Retrieval.Chunker.Chunk

  @spec chunker_version() :: pos_integer()
  def chunker_version(), do: error()

  @spec chunk_code(String.t(), String.t()) :: [Chunk.t()]
  def chunk_code(_path, _code), do: error()

  @spec grep_file(String.t(), String.t()) :: [integer()]
  def grep_file(_path, _pattern), do: error()

  @spec clone(String.t(), String.t(), pos_integer()) :: boolean()
  def clone(_repo_url, _dest_path, _depth), do: error()

  @spec commits(String.t()) :: map()
  def commits(_repo_root_path), do: error()

  @spec unified_diff(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def unified_diff(_old_path, _new_path, _old_content, _new_content), do: error()

  @spec unified_diff(atom(), String.t(), String.t(), String.t(), String.t()) :: String.t()
  def unified_diff(:create, _old_path, new_path, _old_content, new_content) do
    unified_diff("/dev/null", Path.join("b", new_path), "", new_content)
  end

  def unified_diff(:delete, old_path, _new_path, old_content, _new_content) do
    unified_diff(Path.join("a", old_path), "/dev/null", old_content, "")
  end

  def unified_diff(:modify, old_path, new_path, old_content, new_content) do
    unified_diff(Path.join("a", old_path), Path.join("b", new_path), old_content, new_content)
  end

  @spec unified_diffs(String.t()) :: map()
  def unified_diffs(_repo_root_path), do: error()

  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
