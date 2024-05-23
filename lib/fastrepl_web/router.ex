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

  scope "/", FastreplWeb do
    pipe_through [:browser]

    get "/login", AuthController, :login
    get "/logout", AuthController, :logout
  end

  scope "/", FastreplWeb do
    pipe_through [:browser]

    get "/checkout/session", CheckoutController, :session

    live_session :any, on_mount: [{Identity.LiveView, :fetch_identity}] do
      live "/", ThreadsLive, :none

      live "/demo", ThreadsDemoLive, :demo
      live "/demo/thread/:id", ThreadLive, :demo

      live "/dev/debug", DevDebugLive, :none
      live "/dev/url", DevUrlLive, :none
    end

    live_session :only,
      on_mount: [
        {Identity.LiveView, {:redirect_if_unauthenticated, to: "/"}},
        {FastreplWeb.Auth, :fetch_account}
      ] do
      live "/thread/:id", ThreadLive, :none
      live "/setting", SettingLive, :none
      live "/github/setup", GithubSetupLive, :none
    end
  end

  scope "/api", FastreplWeb do
    pipe_through [:api]

    get "/patch/:id", GitPatchController, :patch
  end

  scope "/webhook", FastreplWeb do
    pipe_through [:api]

    post "/github", GithubWebhookController, :index
  end

  scope "/" do
    pipe_through [:browser]

    get "/auth/:provider", Identity.Controller, :oauth_request, as: :identity
    get "/auth/:provider/callback", Identity.Controller, :oauth_callback, as: :identity
  end
end
