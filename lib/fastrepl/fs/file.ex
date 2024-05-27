defmodule Fastrepl.FS.File do
  defstruct [:path, :content]

  alias __MODULE__
  @type t :: %File{path: String.t(), content: String.t()}
end
