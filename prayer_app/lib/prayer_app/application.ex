defmodule PrayerApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PrayerAppWeb.Telemetry,
      PrayerApp.Repo,
      {DNSCluster, query: Application.get_env(:prayer_app, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PrayerApp.PubSub},
      # Start a worker by calling: PrayerApp.Worker.start_link(arg)
      # {PrayerApp.Worker, arg},
      # Start to serve requests, typically the last entry
      PrayerAppWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PrayerApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PrayerAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
