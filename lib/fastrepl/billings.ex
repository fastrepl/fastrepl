defmodule Fastrepl.Billings do
  import Ecto.Query, warn: false
  alias Fastrepl.Repo

  alias Fastrepl.Billings.Billing
  alias Fastrepl.Accounts.Account

  def create_billing(%Account{} = account, %Stripe.Customer{} = customer) do
    %Billing{}
    |> Billing.changeset(%{})
    |> Ecto.Changeset.put_assoc(:account, account)
    |> Ecto.Changeset.put_change(:stripe_customer, customer)
    |> Repo.insert()
  end

  @spec get_billing(Account.t()) :: Billing.t() | nil
  def get_billing(%Account{} = account) do
    from(billing in Billing, where: billing.account_id == ^account.id)
    |> Repo.one()
  end

  def set_customer(%Billing{} = billing, %Stripe.Customer{} = customer) do
    billing
    |> Billing.changeset(%{})
    |> Ecto.Changeset.put_change(:stripe_customer, customer)
    |> Repo.update()
  end

  def set_subscription(%Billing{} = billing, %Stripe.Subscription{} = subscription) do
    billing
    |> Billing.changeset(%{})
    |> Ecto.Changeset.put_change(:stripe_subscription, subscription)
    |> Repo.update()
  end
end
