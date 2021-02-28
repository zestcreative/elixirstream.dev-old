# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :elixir_stream,
  ecto_repos: [ElixirStream.Repo]

# Configures the endpoint
config :elixir_stream, ElixirStreamWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rQRP/j3RkvaPk6NcMaNmAifMzy19/BRrAJHZObDJMHAzxzfpVv6dJsI3Mjw07LUl",
  render_errors: [view: ElixirStreamWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ElixirStream.PubSub,
  live_view: [signing_salt: "tail8oyy"]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
