defmodule ElixirStream.Accounts do
  @moduledoc "Accounts"
  @github_admins ~w[643967]

  alias ElixirStream.Accounts.Query
  alias ElixirStream.Accounts.User
  alias ElixirStream.Repo

  @spec admin?(%User{}) :: boolean()
  def admin?(%{source: :github, source_id: id}) when id in @github_admins, do: true
  def admin?(_), do: false

  @spec find_or_create(map()) ::
          {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def find_or_create(%Ueberauth.Auth{} = auth) do
    case find(to_string(auth.provider), to_string(auth.uid)) do
      nil -> create(auth)
      user -> {:ok, user}
    end
  end

  @spec find(String.t(), String.t()) :: nil | %User{}
  def find(source, source_id) do
    source
    |> Query.by_source_and_source_id(source_id)
    |> Repo.one()
  end

  @spec create(map()) :: {:ok, %User{}} | {:error, Ecto.Changeset.t()}
  def create(%Ueberauth.Auth{} = auth) do
    %User{}
    |> User.changeset(%{
      source: to_string(auth.provider),
      source_id: to_string(auth.uid),
      name: name_from_auth(auth),
      avatar: avatar_from_auth(auth),
      username: username_from_auth(auth)
    })
    |> Repo.insert()
  end

  defp username_from_auth(%{info: %{nickname: username}}), do: username

  defp name_from_auth(%{info: %{name: name}}) when is_binary(name), do: name

  defp name_from_auth(%{info: %{first_name: first, last_name: last}})
       when is_binary(first) and is_binary(last) and first != "" and last != "" do
    Enum.join([first, last], " ")
  end

  defp name_from_auth(auth), do: username_from_auth(auth)

  defp avatar_from_auth(%{info: %{urls: %{avatar_url: image}}}), do: image
  defp avatar_from_auth(_auth), do: nil
end
