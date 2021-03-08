defmodule ElixirStreamWeb.GuardianPipeline do
  use Guardian.Plug.Pipeline,
    otp_app: :elixir_stream,
    module: ElixirStream.Accounts.Guardian,
    error_handler: ElixirStreamWeb.AuthErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
