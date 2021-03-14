defmodule ElixirStreamWeb.Live.Auth do
  @moduledoc "Helpers to assist with loading the user from the session into the socket"

  import Phoenix.LiveView
  import ElixirStreamWeb.Gettext
  alias Ecto.Changeset

  @claims %{"typ" => "access"}
  @token_key "guardian_default_token"

  def assign_defaults(socket, session) do
    Phoenix.LiveView.assign(
      socket,
      searching: false,
      search_changeset: search_changeset(%{})
    )
    |> load_user(session)
  end

  @search_types %{module: :string, q: :string}
  def search_changeset(params) do
    {%{}, @search_types}
    |> Changeset.cast(params, Map.keys(@search_types))
    |> Changeset.validate_length(:q, max: 75)
  end

  def require_user(socket) do
    if socket.assigns.current_user.id do
      {:ok, socket}
    else
      {:ok,
       socket
       |> put_flash(:error, gettext("Not logged in"))
       |> redirect(to: "/")}
    end
  end

  def load_user(socket, %{@token_key => token}) do
    Phoenix.LiveView.assign_new(socket, :current_user, fn ->
      with {:ok, claims} <-
             Guardian.decode_and_verify(ElixirStream.Accounts.Guardian, token, @claims),
           {:ok, user} <- ElixirStream.Accounts.Guardian.resource_from_claims(claims) do
        user
      else
        _ -> %ElixirStream.Accounts.User{}
      end
    end)
  end

  def load_user(socket, _) do
    Phoenix.LiveView.assign_new(socket, :current_user, fn ->
      %ElixirStream.Accounts.User{}
    end)
  end
end
