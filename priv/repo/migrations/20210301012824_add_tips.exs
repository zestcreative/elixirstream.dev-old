defmodule ElixirStream.Repo.Migrations.AddTips do
  use Ecto.Migration
  @disable_ddl_transaction true
  @disable_migration_lock true

  def change do
    execute(
      "CREATE EXTENSION IF NOT EXISTS \"pg_trgm\"",
      "DROP EXTENSION IF EXISTS \"pg_trgm\""
    )

    create table("tips", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :title, :text, null: false
      add :description, :text, null: false
      add :code, :text, null: false
      add :code_image_url, :string
      add :published_at, :utc_datetime
      add :approved, :boolean, null: false, default: false
      add :twitter_status_id, :string

      add :contributor_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false

      timestamps()
    end

    execute """
    ALTER TABLE tips
    ADD COLUMN searchable tsvector
     GENERATED ALWAYS AS (to_tsvector('english', coalesce(title, '') || ' ' || coalesce(description, ''))) STORED
    """, """
    ALTER TABLE tips DROP COLUMN searchable
    """

    create index("tips", ["searchable"], name: :tips_searchable_index, using: "GIN", concurrently: true)
  end
end
