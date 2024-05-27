defmodule Fastrepl.FS.File do
  @derive {Jason.Encoder, only: [:path, :content]}
  defstruct [:path, :content]

  alias __MODULE__
  @type t :: %File{path: String.t(), content: String.t()}
end
