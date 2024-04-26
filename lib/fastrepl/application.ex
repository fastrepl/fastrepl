defmodule Fastrepl.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :unique, name: Fastrepl.OrchestratorRegistry},
      {Registry, keys: :unique, name: Fastrepl.VectordbRegistry},
      {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},
      FastreplWeb.Telemetry,
      Fastrepl.Repo,
      {DNSCluster, query: Application.get_env(:fastrepl, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Fastrepl.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Fastrepl.Finch},
      # Start a worker by calling: Fastrepl.Worker.start_link(arg)
      # {Fastrepl.Worker, arg},
      # Start to serve requests, typically the last entry
      FastreplWeb.Endpoint
    ]

    children =
      if Application.get_env(:fastrepl, :env) != :test do
        [{Redix, {Application.fetch_env!(:fastrepl, :redis_url), [name: :redix]}}] ++ children
      else
        children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Fastrepl.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FastreplWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
