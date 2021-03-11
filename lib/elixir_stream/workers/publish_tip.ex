defmodule ElixirStream.Workers.PublishTip do
  use Oban.Worker, queue: :publish_tip
  alias ElixirStream.{Catalog, Twitter}

  @impl Oban.Worker
  def perform(%{args: %{"tip_id" => tip_id}}) do
    if tip = Catalog.find_tip(tip_id) do
      Twitter.publish(tip)
    else
      :ok
    end
  end
end
