# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir_stream,
  ecto_repos: [ElixirStream.Repo],
  generators: [binary_id: true]

config :elixir_stream, ElixirStream.Repo,
  migration_timestamps: [type: :utc_datetime]

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

config :ueberauth, Ueberauth,
  json_library: Jason,
  providers: [
    github: {Ueberauth.Strategy.Github, [
      allow_private_emails: true,
      send_redirect_uri: true,
      default_scope: "read:user"
    ]}
  ]

config :ueberauth, Ueberauth.Strategy.Github.OAuth,
  client_id: System.get_env("GITHUB_CLIENT_ID"),
  client_secret: System.get_env("GITHUB_CLIENT_SECRET")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
