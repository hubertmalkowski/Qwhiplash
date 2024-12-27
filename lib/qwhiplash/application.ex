defmodule Qwhiplash.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      QwhiplashWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:qwhiplash, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Qwhiplash.PubSub},
      Qwhiplash.GameDynamicSupervisor,
      # Start a worker by calling: Qwhiplash.Worker.start_link(arg)
      # {Qwhiplash.Worker, arg},
      # Start to serve requests, typically the last entry
      QwhiplashWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Qwhiplash.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    QwhiplashWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
