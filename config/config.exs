# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :elixir_stream,
  ecto_repos: [ElixirStream.Repo],
  storage: ElixirStream.Storage.LocalImplementation,
  generators: [binary_id: true],
  app_env: Mix.env()

config :elixir_stream, ElixirStream.Repo, migration_timestamps: [type: :utc_datetime]

# Configures the endpoint
config :elixir_stream, ElixirStreamWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "rQRP/j3RkvaPk6NcMaNmAifMzy19/BRrAJHZObDJMHAzxzfpVv6dJsI3Mjw07LUl",
  render_errors: [view: ElixirStreamWeb.ErrorView, accepts: ~w(html json), layout: false],
  pubsub_server: ElixirStream.PubSub,
  live_view: [signing_salt: "tail8oyy"]

# Configures Elixir's Logger
config :logger,
  backends: [:console, Sentry.LoggerBackend]

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

config :elixir_stream, ElixirStream.Mailer,
  adapter: Bamboo.SendGridAdapter,
  hackney_opts: [
    recv_timeout: :timer.minutes(1),
    connect_timeout: :timer.minutes(1)
  ]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :elixir_stream, Oban,
  repo: ElixirStream.Repo,
  plugins: [
    {Oban.Plugins.Cron,
     crontab: [
       {"0 */4 * * *", ElixirStream.Workers.ApprovalReminder, queue: :mailer}
     ]}
  ],
  queues: [publish_tip: 1, mailer: 1]

config :elixir_stream, ElixirStream.Storage, bucket: "elixirstream.dev"

config :elixir_stream, ElixirStream.Accounts.Guardian,
  issuer: "elixir_stream",
  secret_key: "nhjkfizPNUD4NyjudO8Nuhu8X7EOPI5XYNnwn+8iI8Pd/mcI8DkZRoQJ9CZT/NXa"

config :ex_aws,
  json_codec: Jason,
  http_client: ElixirStream.Storage.ExAwsClient,
  region: "us-east-1"

config :ex_aws, :s3, host: "us-east-1.linodeobjects.com"

config :ueberauth, Ueberauth,
  json_library: Jason,
  providers: [
    github:
      {Ueberauth.Strategy.Github,
       [
         allow_private_emails: true,
         send_redirect_uri: true,
         default_scope: "read:user"
       ]},
    twitter: {Ueberauth.Strategy.Twitter, []}
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
