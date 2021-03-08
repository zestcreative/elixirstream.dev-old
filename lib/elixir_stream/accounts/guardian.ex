defmodule ElixirStream.Accounts.Guardian do
  use Guardian, otp_app: :elixir_stream

  def subject_for_token(%{id: id} = _subject, _claims) do
    {:ok, to_string(id)}
  end
  def subject_for_token(_, _), do: {:error, :not_found}

  def resource_from_claims(claims) do
    id = claims["sub"]
    case ElixirStream.Accounts.find(id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end
end
