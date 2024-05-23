defmodule FastreplWeb.StripeWebhookHandler do
  @behaviour Stripe.WebhookHandler

  @moduledoc """
  https://hexdocs.pm/stripity_stripe/Stripe.WebhookPlug.html
  https://dashboard.stripe.com/test/webhooks
  """

  @impl true
  def handle_event(%Stripe.Event{type: "checkout.session.completed"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "invoice.paid"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "invoice.payment_failed"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.created"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.deleted"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.updated"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.created"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.deleted"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.paused"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.pending_update_applied"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.pending_update_expired"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.trial_will_end"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "customer.subscription.updated"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "subscription_schedule.aborted"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "subscription_schedule.canceled"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "subscription_schedule.completed"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "subscription_schedule.created"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "subscription_schedule.expiring"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "subscription_schedule.released"} = _event) do
    :ok
  end

  @impl true
  def handle_event(%Stripe.Event{type: "subscription_schedule.updated"} = _event) do
    :ok
  end

  @impl true
  def handle_event(_event), do: :ok
end
