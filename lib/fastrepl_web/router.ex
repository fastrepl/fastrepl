defmodule FastreplWeb.Router do
  use FastreplWeb, :router
  import Identity.Plug

  if Application.compile_env(:fastrepl, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_identity
    plug :fetch_live_flash
    plug :put_root_layout, html: {FastreplWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through [:browser]

    get "/login", FastreplWeb.AuthController, :login
    get "/logout", FastreplWeb.AuthController, :logout
    get "/auth/:provider", Identity.Controller, :oauth_request, as: :identity
    get "/auth/:provider/callback", Identity.Controller, :oauth_callback, as: :identity
  end

  scope "/" do
    pipe_through [:browser]

    get "/checkout/session", FastreplWeb.CheckoutController, :session

    live_session :app,
      on_mount: [
        {Identity.LiveView, {:redirect_if_unauthenticated, to: "/login"}},
        {FastreplWeb.Auth, :fetch_account},
        FastreplWeb.Nav
      ] do
      live "/", FastreplWeb.ThreadsLive, :none
      live "/settings", FastreplWeb.SettingsLive, :none
      live "/threads", FastreplWeb.ThreadsDemoLive, :none
      live "/thread/:id", FastreplWeb.ThreadLive, :none
    end

    live_session :others,
      on_mount: [
        {Identity.LiveView, {:redirect_if_unauthenticated, to: "/login"}},
        {FastreplWeb.Auth, :fetch_account}
      ] do
      live "/github/setup", FastreplWeb.GithubSetupLive, :none
    end
  end
end
