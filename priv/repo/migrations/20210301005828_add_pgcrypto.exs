defmodule ElixirStream.Repo.Migrations.AddPgcrypto do
  @moduledoc "Add PgCrypto so we can have Postgres generate it's own IDs"
  use Ecto.Migration

  def change do
    execute(
      "CREATE EXTENSION IF NOT EXISTS \"pgcrypto\"",
      "DROP EXTENSION IF EXISTS \"pgcrypto\""
    )
  end
end
