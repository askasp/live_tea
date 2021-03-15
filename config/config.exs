# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

# Configures the endpoint
config :live_tea, LiveTeaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "uJ/tDg7FNqxJ1WZt4+MnK/+YutmyUHjSDhtMKtLADP5pnVMBpm8JJ+d3TM/PNgmH",
  render_errors: [view: LiveTeaWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: LiveTea.PubSub,
  live_view: [signing_salt: "zGw8qyp/"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.


config :live_tea, LiveTea.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.Extreme,
    serializer: Commanded.Serialization.JsonSerializer,
    stream_prefix: "live_tea",
    extreme: [
      db_type: :node,
      host: "localhost",
      port: 1113,
      username: "admin",
      password: "changeit",
      reconnect_delay: 2_000,
      max_attempts: :infinity
    ]
  ]


import_config "#{Mix.env()}.exs"

