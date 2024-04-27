defmodule Fastrepl.Retrieval.Grep do
  alias Fastrepl.Native.CodeUtils

  def grep_file(path, pattern) do
    CodeUtils.grep_file(path, pattern)
  end
end
