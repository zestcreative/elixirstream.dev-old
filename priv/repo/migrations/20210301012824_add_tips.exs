defmodule ElixirStream.Repo.Migrations.AddTips do
  use Ecto.Migration

  def change do
    create table("tips", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :title, :text, null: false
      add :description, :text, null: false
      add :code, :text, null: false
      add :code_image_url, :string
      add :published_at, :utc_datetime

      add :contributor_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false

      timestamps()
    end
  end
end
