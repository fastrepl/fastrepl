require Protocol
Protocol.derive(Jason.Encoder, Stripe.Customer)
Protocol.derive(Jason.Encoder, Stripe.Subscription)
Protocol.derive(Jason.Encoder, Stripe.SubscriptionItem)
Protocol.derive(Jason.Encoder, Stripe.List)
Protocol.derive(Jason.Encoder, Stripe.Plan)
Protocol.derive(Jason.Encoder, Stripe.Price)

defmodule Fastrepl.Billings.Billing do
  use Ecto.Schema
  import Ecto.Changeset

  @type t :: %__MODULE__{}

  alias Fastrepl.Accounts.Account

  schema "billings" do
    belongs_to :account, Account
    field :stripe_customer, :map
    field :stripe_subscription, :map

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(billing, attrs) do
    billing
    |> cast(attrs, [])
    |> assoc_constraint(:account)
  end
end
