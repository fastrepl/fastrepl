defmodule Fastrepl.Sessions.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.Sessions.Session

  @type t :: %Ticket{}

  schema "tickets" do
    field :type, Ecto.Enum, values: [:github, :fastrepl], virtual: true
    field :github_repo, :map, virtual: true
    field :github_issue, :map, virtual: true

    field :github_repo_full_name, :string
    field :github_repo_sha, :string
    field :github_issue_number, :integer

    field :fastrepl_issue_content, :string

    belongs_to :session, Session

    timestamps(type: :utc_datetime)
  end

  # TODO: fix cast
  @spec changeset(Ticket.t(), map()) :: Ecto.Changeset.t()
  @doc false
  def changeset(%Ticket{} = ticket, %{github_issue_number: _} = attrs) do
    ticket
    |> cast(attrs, [:github_repo_full_name, :github_repo_sha, :github_issue_number])
    |> validate_required([:github_repo_full_name, :github_repo_sha, :github_issue_number])
    |> assoc_constraint(:session)
  end
end
