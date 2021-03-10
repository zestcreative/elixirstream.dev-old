defmodule ElixirStream.Repo.Migrations.AddTipUpvotes do
  use Ecto.Migration

  def change do
    create table("tip_upvotes", primary_key: false) do
      add :id, :binary_id, primary_key: true, default: fragment("gen_random_uuid()")

      add :tip_id, references(:tips, type: :binary_id, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all), null: false
      timestamps()
    end

    alter table("tips") do
      add :upvote_count, :integer, null: false, default: 0
    end

    create unique_index(:tip_upvotes, [:tip_id, :user_id])
  end
end
