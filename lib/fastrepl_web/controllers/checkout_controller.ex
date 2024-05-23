defmodule FastreplWeb.CheckoutController do
  use FastreplWeb, :controller
  require Logger

  alias Stripe.Checkout.Session

  def session(conn, params) do
    item_index = Map.get(params, "i", "0") |> String.to_integer()

    item =
      Application.fetch_env!(:fastrepl, :stripe_items)
      |> Enum.at(item_index)

    result =
      Session.create(%{
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
