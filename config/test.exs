use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :live_tea, LiveTeaWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

config :live_tea, LiveTea.App,
  event_store: [
    adapter: Commanded.EventStore.Adapters.InMemory,
    serializer: Commanded.Serialization.JsonSerializer
  ]
