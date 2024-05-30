defmodule Fastrepl.Sessions.Ticket do
  use Ecto.Schema
  import Ecto.Changeset

  alias __MODULE__
  alias Fastrepl.Sessions.Session

  @type t :: %Ticket{}

  # when ticket is created from github issue
  @github_fields [
    :base_commit_sha,
    :github_repo_full_name,
    :github_issue_number
  ]

  # when ticket is created internally or from web app
  @fastrepl_fields [
    :base_commit_sha,
    :github_repo_full_name,
    :fastrepl_issue_content
  ]

  @derive {Jason.Encoder, only: [:github_repo, :github_issue]}
  schema "tickets" do
    field :github_repo, :map, virtual: true
    field :github_issue, :map, virtual: true

    field :type, Ecto.Enum, values: [:github, :fastrepl]
    field :base_commit_sha, :string
    field :github_repo_full_name, :string
    field :github_issue_number, :integer

    field :fastrepl_issue_content, :string

    belongs_to :session, Session

    timestamps(type: :utc_datetime)
  end

  def changeset(%Ticket{} = ticket, %{github_issue_number: _} = attrs) do
    ticket
    |> cast(attrs, @github_fields)
    |> validate_required(@github_fields)
    |> put_change(:type, :github)
  end

  def changeset(%Ticket{} = ticket, %{fastrepl_issue_content: _} = attrs) do
    ticket
    |> cast(attrs, @fastrepl_fields)
    |> validate_required(@fastrepl_fields)
    |> put_change(:type, :fastrepl)
  end
end
