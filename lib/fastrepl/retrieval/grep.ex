defmodule Fastrepl.Retrieval.Grep do
  alias Fastrepl.Native.CodeUtils

  def grep(path, code) do
    CodeUtils.grep(path, code)
  end
end
