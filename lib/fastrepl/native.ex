defmodule Fastrepl.Native.CodeUtils do
  use Rustler, otp_app: :fastrepl, crate: :code_utils
  alias Fastrepl.Retrieval.Chunker.Chunk

  @spec chunk_code(String.t(), String.t()) :: [Chunk.t()]
  def chunk_code(_path, _code), do: error()

  @spec grep(String.t(), String.t()) :: [integer()]
  def grep(_path, _pattern), do: error()

  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
