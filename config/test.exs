import Config

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :fastrepl, Fastrepl.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "fastrepl_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :fastrepl, FastreplWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "ZG4LfGmoE2YsFBaUWvhmJJA22P3g6JbUrUnDQVVocEiwYPwXNWL4gAi+bF/lXUtQ",
  server: false

# In test we don't send emails.
config :fastrepl, Fastrepl.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters.
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

config :fastrepl, Oban, testing: :inline

config :fastrepl, :clone_dir, "./tmp/repos"

config :oapi_github, stack: [{GitHub.Plugin.TestClient, :request, []}]
