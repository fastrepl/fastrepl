defmodule FastreplWeb.CheckoutController do
  use FastreplWeb, :controller
  require Logger

  alias Stripe.Checkout.Session

  def session(conn, %{"a" => account_id, "i" => item_index}) do
    item =
      item_index
      |> String.to_integer()
      |> then(&Enum.at(Application.fetch_env!(:fastrepl, :stripe_items), &1))

    result =
      Session.create(%{
        metadata: %{"account_id" => account_id},
        ui_mode: :hosted,
        mode: :subscription,
        line_items: [%{price: item, quantity: 1}],
        success_url: FastreplWeb.Endpoint.url() <> "/",
        cancel_url: FastreplWeb.Endpoint.url() <> "/"
      })

    case result do
      {:ok, %Session{url: url}} ->
        conn |> redirect(external: url)

      {:error, error} ->
        Logger.error(inspect(error))
        conn |> redirect(to: "/") |> put_flash(:error, "Failed to create checkout session.")
    end
  end
end
