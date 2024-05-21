defmodule Fastrepl.Repository.Comment do
  @moduledoc """
  Comment contains information or instruction about a specific part of a file.
  Eventually, it will be used to create a list of Mutations.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__

  @type t :: %Comment{}

  @derive Jason.Encoder
  @primary_key false
  embedded_schema do
    # relative path
    field :file_path, :string
    field :line_start, :integer
    field :line_end, :integer
    field :content, :string
  end

  @spec new(attrs :: map()) :: {:ok, t} | {:error, Ecto.Changeset.t()}
  def new(attrs \\ %{}) do
    %Comment{}
    |> cast(attrs, [:file_path, :line_start, :line_end, :content])
    |> validate_required([:file_path, :line_start, :line_end, :content])
    |> validate_comment()
    |> apply_action(:insert)
  end

  defp validate_comment(changeset) do
    line_start = changeset |> get_field(:line_start)
    line_end = changeset |> get_field(:line_end)

    cond do
      line_start < 1 ->
        add_error(changeset, :line_start, "should be greater than 0")

      line_start >= line_end ->
        add_error(changeset, :line_end, "should be greater than line start")

      true ->
        changeset
    end
  end
end
