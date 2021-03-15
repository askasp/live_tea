defmodule LiveTea.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false


  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      LiveTeaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: LiveTea.PubSub},
      # Start the Endpoint (http/https)
      LiveTeaWeb.Endpoint,
      LiveTea.App,
      ChatMessagesHandler



      # Start a worker by calling: LiveTea.Worker.start_link(arg)
      # {LiveTea.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: LiveTea.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    LiveTeaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
