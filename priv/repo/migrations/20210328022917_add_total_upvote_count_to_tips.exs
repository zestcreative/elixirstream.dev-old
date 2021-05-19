defmodule ElixirStream.Repo.Migrations.AddTotalUpvoteCountToTips do
  use Ecto.Migration

  def change do
    execute """
            ALTER TABLE tips
            ADD COLUMN total_upvote_count integer
             GENERATED ALWAYS AS (twitter_like_count + upvote_count) STORED
            """,
            """
            ALTER TABLE tips DROP COLUMN total_upvote_count
            """
  end
end
