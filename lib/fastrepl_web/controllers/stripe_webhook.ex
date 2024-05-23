defmodule FastreplWeb.StripeWebhookHandler do
  @behaviour Stripe.WebhookHandler

  @moduledoc """
  https://hexdocs.pm/stripity_stripe/Stripe.WebhookPlug.html
  https://dashboard.stripe.com/test/webhooks
  """
  alias Fastrepl.Billings
  alias Fastrepl.Accounts
  alias Fastrepl.Accounts.Account

  @impl true
  def handle_event(%Stripe.Event{
        type: "customer.created",
        data: %{object: %Stripe.Customer{} = _customer}
      }) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "customer.updated",
        data: %{object: %Stripe.Customer{} = customer}
      }) do
    billing = Billings.get_billing_by_customer_id(customer.id)

    if billing do
      Billings.set_customer(billing, customer)
    else
      :ok
    end
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "customer.deleted",
        data: %{object: %Stripe.Customer{} = _customer}
      }) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "customer.subscription.created",
        data: %{object: %Stripe.Subscription{} = _subscription}
      }) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "customer.subscription.updated",
        data: %{object: %Stripe.Subscription{} = subscription}
      }) do
    billing = Billings.get_billing_by_subscription_id(subscription.id)

    if billing do
      Billings.set_subscription(billing, subscription)
    else
      :ok
    end
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "customer.subscription.deleted",
        data: %{object: %Stripe.Subscription{} = _subscription}
      }) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{
        type: "checkout.session.completed",
        data: %{
          object: %Stripe.Checkout.Session{
            customer: customer_id,
            subscription: subscription_id,
            metadata: %{"account_id" => account_id}
          }
        }
      }) do
    with %Account{} = account <- Accounts.get_account_by_id(account_id),
         {:ok, customer} <- Stripe.Customer.retrieve(customer_id),
         {:ok, subscription} <- Stripe.Subscription.retrieve(subscription_id),
         {:ok, _billing} <- Billings.create_billing(account, customer, subscription) do
      :ok
    else
      _ -> :error
    end
  end

  @impl true
  def handle_event(_event), do: :ok
end
