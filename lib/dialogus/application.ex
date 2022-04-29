defmodule Dialogus.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      DialogusWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Dialogus.PubSub},
      # Start the Endpoint (http/https)
      DialogusWeb.Endpoint,
      # Start the Presence system
      Dialogus.Presence,
      # Start the State supervisor
      Dialogus.State
      # Start a worker by calling: Dialogus.Worker.start_link(arg)
      # {Dialogus.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Dialogus.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    DialogusWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
