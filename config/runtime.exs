# In this file, we load production configuration and secrets
# from environment variables. You can also hardcode secrets,
# although such is generally not recommended and you have to
# remember to add this file to your .gitignore.
import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  config :elixir_stream, ElixirStream.Repo,
    # ssl: true,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  config :elixir_stream, ElixirStreamWeb.Endpoint,
    http: [port: System.fetch_env!("PORT"), compress: true],
    url: [scheme: "https", host: System.fetch_env!("HOST"), port: 443],
    secret_key_base: secret_key_base

  config :elixir_stream, ElixirStream.Guardian,
    secret_key: secret_key_base

  config :ex_aws,
    access_key_id: [System.fetch_env!("S3_ACCESS_KEY_ID")],
    secret_access_key: [System.fetch_env!("S3_SECRET_ACCESS_KEY")]

  config :ueberauth, Ueberauth.Strategy.Github.OAuth,
    client_id: System.fetch_env!("GITHUB_CLIENT_ID"),
    client_secret: System.fetch_env!("GITHUB_CLIENT_SECRET")

  config :ueberauth, Ueberauth.Strategy.Twitter.OAuth,
    consumer_key: System.get_env("TWITTER_LOGIN_CONSUMER_KEY"),
    consumer_secret: System.get_env("TWITTER_LOGIN_CONSUMER_SECRET")
end

silicon_bin =
  System.find_executable("silicon") || raise "needs 'silicon' installed."
