defmodule ElixirStream.Workers.UpdateTwitterLikeCounts do
  @moduledoc """
  We want to update approved and published within 6mo tips w/ recent twitter likes.
  After 6mo, we're going to consider the tip too old to check Twitter.
  Twitter's rate limit on this endpoint is 900 requests per 15min.
  """

  use Oban.Worker, queue: :twitter
  alias ElixirStream.{Catalog, Repo, Twitter}
  require Logger

  @about_6mo_ago -15_780_000

  @impl Oban.Worker
  def perform(_) do
    Logger.info("Updating Twitter Likes")

    stream =
      Catalog.list_tips(
        by_latest: true,
        limit: 800,
        max_rows: 100,
        approved: true,
        published_at_gte: DateTime.add(DateTime.utc_now(), @about_6mo_ago, :second),
        stream: true,
        unpublished: false
      )

    Repo.transaction(fn ->
      Enum.reduce(stream, nil, fn tip, _acc ->
        case Twitter.get_status(tip) do
          {:ok, %{"public_metrics" => %{"like_count" => likes}}} ->
            Catalog.update_tip(tip, %{twitter_like_count: likes})

          {:error, error} ->
            Logger.error("Tip #{tip.id} could not reach Twitter. #{inspect(error)}")
        end
      end)
    end)
  end
end
