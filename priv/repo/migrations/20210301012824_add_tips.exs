defmodule ElixirStream.Repo.Migrations.AddTips do
  use Ecto.Migration

  def change do
    create table("tips", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :description, :text, null: false
      add :code, :text, null: false
      add :published, :boolean, default: false, null: false

      add :contributor_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false

      timestamps()
    end
  end
end
