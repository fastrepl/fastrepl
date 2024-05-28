defmodule Fastrepl.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.Sessions.Ticket
  alias Fastrepl.Sessions.Comment
  alias Fastrepl.FS.Patch

  @type t :: %Session{}

  schema "tickets" do
    field :status, Ecto.Enum, values: [:foo, :bar, :baz]
    field :display_id, :string
    field :github_issue_comment_id, :integer

    has_one :ticket, Ticket
    has_many :comments, Comment
    has_many :patches, Patch

    timestamps(type: :utc_datetime)
  end

  def changeset(%Session{} = ticket, attrs) do
    ticket
    |> cast(attrs, [])
    |> validate_required([])
    |> assoc_constraint(:session)
  end
end