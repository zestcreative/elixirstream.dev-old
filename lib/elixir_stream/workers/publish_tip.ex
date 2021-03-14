defmodule ElixirStream.Workers.PublishTip do
  use Oban.Worker, queue: :publish_tip
  alias ElixirStream.{Catalog, Twitter}

  @impl Oban.Worker
  def perform(%{args: %{"tip_id" => tip_id}}) do
    case Catalog.find_tip(tip_id) do
      %{twitter_status_id: nil} = tip ->
        Twitter.publish(tip)

      _ ->
        :ok
    end
  end
end
