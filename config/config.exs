# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :fastrepl,
  ecto_repos: [Fastrepl.Repo],
  generators: [timestamp_type: :utc_datetime]

# Configures the endpoint
config :fastrepl, FastreplWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [html: FastreplWeb.ErrorHTML, json: FastreplWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: Fastrepl.PubSub,
  live_view: [signing_salt: "q5YN7qXI"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :fastrepl, Fastrepl.Mailer, adapter: Swoosh.Adapters.Local

# Configure esbuild (the version is required)
# config :esbuild,
#   version: "0.17.11",
#   fastrepl: [
#     args:
#       ~w(js/app.js --bundle --target=es2017 --outdir=../priv/static/assets --external:/fonts/* --external:/images/*),
#     cd: Path.expand("../assets", __DIR__),
#     env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
#   ]

# Configure tailwind (the version is required)
config :tailwind,
  version: "3.4.0",
  fastrepl: [
    args: ~w(
      --config=tailwind.config.js
      --input=css/app.css
      --output=../priv/static/assets/app.css
    ),
    cd: Path.expand("../assets", __DIR__)
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :posthog,
  api_url: "https://us.i.posthog.com",
  api_key: "phc_qdLGlOK8YuOSe6dbBNlD3QbSzjASgIuJevfB9Xi4gKz"

config :identity, repo: Fastrepl.Repo, user: Identity.User

config :ueberauth, Ueberauth,
  providers: [
    github: {Ueberauth.Strategy.Github, []}
  ]

config :fastrepl, Oban,
  engine: Oban.Engines.Basic,
  queues: [default: 10],
  repo: Fastrepl.Repo

config :fastrepl, :env, Mix.env()
config :fastrepl, :root, File.cwd!()

config :fastrepl, :orchestrator_registry, Fastrepl.OrchestratorRegistry
config :fastrepl, :chat_manager_registry, Fastrepl.ChatManagerRegistry

config :fastrepl, :cache, Fastrepl.Cache.Redis
config :fastrepl, :embedding, Fastrepl.Retrieval.Embedding.OpenAIWithCache

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
