defmodule ElixirStreamWeb.Live.Auth do
  @moduledoc "Helpers to assist with loading the user from the session into the socket"

  import Phoenix.LiveView
  import ElixirStreamWeb.Gettext
  alias Ecto.Changeset

  @claims %{"typ" => "access"}
  @token_key "guardian_default_token"

  def assign_defaults(socket) do
    Phoenix.LiveView.assign(
      socket,
      searching: false,
      search_changeset: search_changeset(%{})
    )
  end

  @search_types %{module: :string, q: :string}
  def search_changeset(params) do
    {%{}, @search_types}
    |> Changeset.cast(params, Map.keys(@search_types))
    |> Changeset.validate_length(:q, max: 75)
  end

  def require_user(socket, session, opts \\ []) do
    socket = load_user(socket, session)
    if socket.assigns.current_user do
      {:ok, socket, opts}
    else
      {:ok,
        socket
        |> put_flash(:error, gettext("Not logged in"))
        |> redirect(to: "/")}
    end
  end
  def require_user(_), do: {:error, :not_logged_in}

  def load_user(socket, %{@token_key => token}) do
    Phoenix.LiveView.assign_new(socket, :current_user, fn ->
      with {:ok, claims} <- Guardian.decode_and_verify(ElixirStream.Accounts.Guardian, token, @claims),
          {:ok, user} <- ElixirStream.Accounts.Guardian.resource_from_claims(claims) do
        user
      else
        _ -> nil
      end
    end)
  end
  def load_user(socket, _), do: socket
end
