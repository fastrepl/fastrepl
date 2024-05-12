defmodule FastreplWeb.Router do
  use FastreplWeb, :router

  import FastreplWeb.GithubAuth

  if Application.compile_env(:fastrepl, :dev_routes) do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {FastreplWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_github_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", FastreplWeb do
    pipe_through [:browser]

    live_session :main,
      on_mount: [{FastreplWeb.GithubAuth, :mount_current_user}] do
      live "/", ThreadsLive, :none
      live "/thread/:id", ThreadLive, :none

      live "/demo", ThreadsDemoLive, :demo
      live "/demo/thread/:id", ThreadLive, :demo

      live "/dev/debug", DevDebugLive, :none
      live "/dev/url", DevUrlLive, :none
    end
  end

  scope "/api", FastreplWeb do
    pipe_through [:api]

    get "/patch/:id", GitPatchController, :patch
  end

  scope "/auth/github", FastreplWeb do
    pipe_through [:browser]

    get "/", GithubAuthController, :sign_in
    get "/out", GithubAuthController, :sign_out
    get "/callback", GithubAuthController, :callback
  end
end
