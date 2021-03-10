# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     ElixirStream.Repo.insert!(%ElixirStream.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias ElixirStream.Repo
alias ElixirStream.Catalog.Tip
alias ElixirStream.Accounts.User

user = Repo.insert!(%User{
  source: :github,
  source_id: "123123",
  name: "Demo User",
  avatar: "https://images.unsplash.com/photo-1598886221321-26aa46a669f2?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=face&w=1024&h=1024&q=80&",
  username: "demo_user",
  twitter: "demouser",
})

Repo.insert!(%Tip{
  title: "Pattern match on strings",
  approved: true,
  description: """
  You may know that the <> operator is used to concat binaries (strings)...but did you also know you can use it for pattern matching binaries?
  """,
  code: """
  iex> "You can" <> " " <> "concat binaries!"
  #=> "You can concat binaries!"

  iex> case "user:b4c52a55-e2d9-446f-908d-42c9812f2e8a" do
         "admin:" <> id -> {:admin, id}
         "user:" <> id -> {:user, id}
         _ -> {:error, :invalid_format}
       end
  {:user, "b4c52a55-e2d9-446f-908d-42c9812f2e8a"}
  """,
  published_at: DateTime.utc_now(),
  contributor_id: user.id
})

Repo.insert!(%Tip{
  title: "Oban unique jobs",
  approved: true,
  description: """
  Did you know that Oban lets you specify constraints to prevent enqueuing duplicate jobs? Uniqueness is enforced as jobs are inserted, dynamically and atomically.

  https://hexdocs.pm/oban/Oban.html#module-unique-jobs
  """,
  code: """
  defmodule MyApp.BusinessWorker do
    use Oban.Worker, unique: [period: 60]

    # ...
  end

  # Manually override the unique period for a single job
  MyApp.BusinessWorker.new(%{id: 1}, unique: [period: 120])

  # Override a job to have an infinite unique period, which lasts
  # as long as jobs are persisted
  MyApp.BusinessWorker.new(%{id: 1}, unique: [period: :infinity])
  """,
  published_at: DateTime.utc_now(),
  contributor_id: user.id
})
