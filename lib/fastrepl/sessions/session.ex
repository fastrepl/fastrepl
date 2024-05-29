defmodule Fastrepl.Sessions.Session do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.Sessions.Ticket
  alias Fastrepl.Sessions.Comment
  alias Fastrepl.FS.Patch
  alias Fastrepl.Accounts.Account

  @type t :: %Session{
          status: :init_0 | :clone_1 | :index_2 | :start_3 | :execute_4,
          display_id: String.t(),
          ticket: Ticket.t(),
          comments: [Comment.t()],
          patches: [Patch.t()]
        }

  schema "sessions" do
    field :status, Ecto.Enum,
      values: [:init_0, :clone_1, :index_2, :start_3, :execute_4],
      default: :init_0

    field :display_id, :string

    belongs_to :account, Account
    has_one :ticket, Ticket
    has_many :comments, Comment
    has_many :patches, Patch

    timestamps(type: :utc_datetime)
  end

  def changeset(%Session{} = session, attrs) do
    session
    |> cast(attrs, [:account_id, :status, :display_id])
    |> validate_required([:account_id, :display_id])
    |> assoc_constraint(:account)
  end
end
