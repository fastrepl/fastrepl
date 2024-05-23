defmodule Fastrepl.BillingTest do
  use Fastrepl.DataCase

  import Fastrepl.UsersFixtures
  import Fastrepl.AccountsFixtures

  alias Fastrepl.Billings

  describe "billings" do
    test "create_billing/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      customer = %Stripe.Customer{}
      subscription = %Stripe.Subscription{}

      {:ok, billing} = Billings.create_billing(account, customer, subscription)
      assert billing.account_id == account.id
    end

    test "get_billing/1" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      customer = %Stripe.Customer{}
      subscription = %Stripe.Subscription{}

      Billings.create_billing(account, customer, subscription)
      billing = Billings.get_billing(account)

      assert billing.account_id == account.id
    end

    test "set_customer/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      customer_1 = %Stripe.Customer{name: "user_1"}
      customer_2 = %Stripe.Customer{name: "user_2"}
      subscription = %Stripe.Subscription{}

      Billings.create_billing(account, customer_1, subscription)
      billing = Billings.get_billing(account)
      assert billing.stripe_customer["name"] == customer_1.name

      Billings.set_customer(billing, customer_2)
      assert Billings.get_billing(account).stripe_customer["name"] == customer_2.name
    end

    test "set_subscription/2" do
      account = user_fixture() |> account_fixture(%{name: "personal"})
      customer = %Stripe.Customer{name: "user_1"}
      sub_1 = %Stripe.Subscription{id: "sub_1"}
      sub_2 = %Stripe.Subscription{id: "sub_2"}

      Billings.create_billing(account, customer, sub_1)
      billing = Billings.get_billing(account)
      assert Billings.get_billing(account).stripe_subscription["id"] == sub_1.id

      Billings.set_subscription(billing, sub_2)
      assert Billings.get_billing(account).stripe_subscription["id"] == sub_2.id
    end
  end
end
