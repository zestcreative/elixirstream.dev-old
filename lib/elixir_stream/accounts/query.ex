defmodule ElixirStream.Accounts.Query do
  import Ecto.Query
  alias ElixirStream.Accounts.User

  @doc "Find a user by source and source_id"
  def by_source_and_source_id(source, source_id) do
    User
    |> where([u], u.source == ^source)
    |> where([u], u.source_id == ^source_id)
  end

end
