defmodule ElixirStream.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      ElixirStream.Repo,
      # Start the Telemetry supervisor
      ElixirStreamWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: ElixirStream.PubSub},
      # Start the Endpoint (http/https)
      ElixirStreamWeb.Endpoint
      # Start a worker by calling: ElixirStream.Worker.start_link(arg)
      # {ElixirStream.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: ElixirStream.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    ElixirStreamWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
