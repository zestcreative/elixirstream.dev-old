defmodule ElixirStream.Workers.ApprovalReminder do
  use Oban.Worker, queue: :mailer
  alias ElixirStream.Catalog

  @impl Oban.Worker
  def perform(_) do
    [only_not_approved: true]
    |> Catalog.list_tips()
    |> case do
      [] ->
        :ok

      tips ->
        tips
        |> ElixirStream.Email.approval_reminder()
        |> ElixirStream.Mailer.deliver_now!()
    end
  end
end
