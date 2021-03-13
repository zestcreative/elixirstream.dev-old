defmodule ElixirStream.Accounts.Guardian do
  use Guardian, otp_app: :elixir_stream

  def subject_for_token(%{id: id} = _subject, _claims) do
    {:ok, to_string(id)}
  end
  def subject_for_token(_, _), do: {:ok, nil}

  def resource_from_claims(%{"sub" => nil}) do
    {:ok, %ElixirStream.Accounts.User{}}
  end
  def resource_from_claims(%{"sub" => id}) do
    case ElixirStream.Accounts.find(id) do
      nil -> {:ok, %ElixirStream.Accounts.User{}}
      user -> {:ok, user}
    end
  end
end
