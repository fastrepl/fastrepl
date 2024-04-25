defmodule Fastrepl.Native.RustChunker do
  use Rustler, otp_app: :fastrepl, crate: :rust_chunker

  def chunk_code(_path, _code), do: error()
  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
