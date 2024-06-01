defmodule FastreplWeb.Router do
  use FastreplWeb, :router
  import Identity.Plug

  if Application.compile_env(:fastrepl, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
      live "/debug", FastreplWeb.DevDebugLive, :none
      live "/url", FastreplWeb.DevUrlLive, :none
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

  scope "/" do
    get "/patch/:id", FastreplWeb.GitPatchController, :api
  end

  scope "/" do
    pipe_through [:browser]

    get "/patch/view/:id", FastreplWeb.GitPatchController, :view

    get "/login", FastreplWeb.AuthController, :login
    get "/logout", FastreplWeb.AuthController, :logout
    get "/invite/:key", FastreplWeb.AuthController, :invite
    get "/auth/:provider", Identity.Controller, :oauth_request, as: :identity
    get "/auth/:provider/callback", Identity.Controller, :oauth_callback, as: :identity
  end

  scope "/" do
    pipe_through [:browser]

    get "/checkout/session", FastreplWeb.CheckoutController, :session

    live_session :app,
      layout: {FastreplWeb.Layouts, :live},
      on_mount: [
        {Identity.LiveView, {:redirect_if_unauthenticated, to: "/login"}},
        {FastreplWeb.Auth, :fetch_or_create_account},
        FastreplWeb.Nav
      ] do
      live "/", FastreplWeb.MainLive, :none
      live "/sessions", FastreplWeb.SessionsLive, :none
      live "/session/:id", FastreplWeb.SessionLive, :none
      live "/chats", FastreplWeb.ChatsLive, :none
      live "/chat/:id", FastreplWeb.ChatLive, :none
      live "/settings", FastreplWeb.SettingsLive, :none
    end

    live_session :others,
      on_mount: [
        {Identity.LiveView, {:redirect_if_unauthenticated, to: "/login"}},
        {FastreplWeb.Auth, :fetch_or_create_account}
      ] do
      live "/setup/github", FastreplWeb.GithubSetupLive, :none
    end
  end
end
