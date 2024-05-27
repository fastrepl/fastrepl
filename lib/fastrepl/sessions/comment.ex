defmodule Fastrepl.Sessions.Comment do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.Sessions.Session

  @type t :: %Comment{
          file_path: String.t(),
          line_start: integer(),
          line_end: integer(),
          content: String.t()
        }

  @derive {Jason.Encoder, only: [:file_path, :line_start, :line_end, :content]}
  schema "comment" do
    field :file_path, :string
    field :line_start, :integer
    field :line_end, :integer
    field :content, :string

    belongs_to :session, Session
  end

  def changeset(%Comment{} = comment, attrs) do
    comment
    |> cast(attrs, [:file_path, :line_start, :line_end, :content])
    |> assoc_constraint(:session)
    |> validate_required([:file_path, :line_start, :line_end, :content])
    |> validate_comment()
  end

  defp validate_comment(changeset) do
    {line_start, line_end} = {get_field(changeset, :line_start), get_field(changeset, :line_end)}

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
