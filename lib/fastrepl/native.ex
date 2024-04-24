defmodule Fastrepl.Native.RustChunker do
  use Rustler, otp_app: :fastrepl, crate: :rust_chunker

  def add(_a, _b), do: error()
  defp error(), do: :erlang.nif_error(:nif_not_loaded)
end
