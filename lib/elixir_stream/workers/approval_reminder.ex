defmodule ElixirStream.Workers.ApprovalReminder do
  use Oban.Worker, queue: :mailer
  alias ElixirStream.{Catalog, Email, Mailer}

  @impl Oban.Worker
  def perform(_) do
    [only_not_approved: true]
    |> Catalog.list_tips()
    |> case do
      [] ->
        :ok

      tips ->
        tips |> Email.approval_reminder() |> Mailer.deliver_now!()
    end
  end
end
