defmodule ElixirStream.Repo.Migrations.AddTwitterLikesToTips do
  use Ecto.Migration

  def change do
    alter table("tips") do
      add :twitter_like_count, :integer, null: false, default: 0
    end
  end
end
