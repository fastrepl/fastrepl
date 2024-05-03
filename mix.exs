defmodule Fastrepl.MixProject do
  use Mix.Project

  def project do
    [
      app: :fastrepl,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {Fastrepl.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Specifies your project dependencies.
  #
  # Type `mix help deps` for examples and options.
  defp deps do
    [
      {:phoenix, "~> 1.7.11"},
      {:phoenix_ecto, "~> 4.4"},
      {:ecto_sql, "~> 3.10"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:phoenix_live_view, "~> 0.20.2"},
      # {:floki, ">= 0.30.0", only: :test},
      {:floki, "~> 0.24"},
      # {:esbuild, "~> 0.8", runtime: Mix.env() == :dev},
      {:tailwind, "~> 0.2", runtime: Mix.env() == :dev},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.1",
       sparse: "optimized",
       app: false,
       compile: false,
       depth: 1},
      {:swoosh, "~> 1.5"},
      {:finch, "~> 0.13"},
      {:telemetry_metrics, "~> 0.6"},
      {:telemetry_poller, "~> 1.0"},
      {:gettext, "~> 0.20"},
      {:jason, "~> 1.2"},
      {:dns_cluster, "~> 0.1.1"},
      {:bandit, "~> 1.2"},
      #
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:mox, "~> 1.0", only: :test},
      {:req, "~> 0.4.0"},
      {:nanoid, "~> 2.1.0"},
      {:bumblebee,
       git: "https://github.com/elixir-nx/bumblebee.git",
       rev: "cb26c2dce95c1c5e7bad4d9ba29115088abfdbe7"},
      {:redix, "~> 1.1"},
      {:castore, ">= 0.0.0"},
      {:retry, "~> 0.18"},
      {:earmark, "~> 1.4"},
      {:assent, "~> 0.2.9"},
      {:rustler, "~> 0.32.1"},
      {:live_svelte, "~> 0.13.1"},
      {:oapi_github, "~> 0.3.3"},
      {:httpoison, "~> 2.0"},
      {:posthog, "~> 0.1"},
      {:langchain,
       git: "https://github.com/brainlid/langchain.git",
       rev: "8befbd25d3b1c065a7c4d8ec402c04601833052f"},
      {:readability, "~> 0.12"},
      {:memoize, "~> 1.4"}
    ]
  end

  # Aliases are shortcuts or tasks specific to the current project.
  # For example, to install project dependencies and perform other setup tasks, run:
  #
  #     $ mix setup
  #
  # See the documentation for `Mix` for more info on aliases.
  defp aliases do
    [
      setup: ["deps.get", "ecto.setup", "cmd --cd assets npm install"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"],
      "assets.setup": ["tailwind.install --if-missing", "esbuild.install --if-missing"],
      "assets.build": ["tailwind fastrepl", "esbuild fastrepl"],
      "assets.deploy": [
        "tailwind fastrepl --minify",
        "cmd --cd assets node build.js --deploy",
        "phx.digest"
      ]
    ]
  end
end
