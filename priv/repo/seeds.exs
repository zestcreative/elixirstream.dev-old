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
  published_at: DateTime.new!(Date.new!(2021, 03, 2), Time.new!(15, 22, 0, 0)),
  contributor_id: user.id
})

Repo.insert!(%Tip{
  title: "ExUnit Test Coverage",
  approved: true,
  description: """
  ExUnit is packed with plenty of great develop experience-related goodies. One of my favotites is the built-in coverage
  reporter!
  """,
  code: """
  $ mix test --cover
  Cover compiling modules ...
  ..

  Finished in 0.06 seconds
  1 doctest, 1 test, 0 failures

  Randomized with seed 213130

  Generating cover results ...

  Percentage | Modules
  -----------|---------------------------
     100.00% | CoverageTest
  -----------|---------------------------
     100.00% | Total

  Generated HTML coverage results in "cover" directory
  """,
  published_at: DateTime.new!(Date.new!(2021, 03, 10), Time.new!(13, 0, 0, 0)),
  contributor_id: user.id
})

Repo.insert!(%Tip{
  title: "Replace Args",
  approved: true,
  description: """
  Did you know that you can selectively replace args when insreting a unique job? With `replace_args`, when an existing
  job matches some unique keys all other args are replaced.
  """,
  code: """
  # Given an existing job with these args:
  %{some_value: 1, other_value: 1, id: 123}

  # Attempting to insert a new job with the same `id` key and different values:
  %{some_value: 2, other_value: 2, id: 123}
  |> MyJob.new(schedule_in: 10, replace_args: true, unique: [keys: [:id]])
  |> Oban.isnert()

  # Will result in a single job with the args:
  %{some_value: 2, other_value: 2, id:123}
  """,
  published_at: DateTime.new!(Date.new!(2021, 03, 4), Time.new!(15, 55, 0, 0)),
  contributor_id: user.id
})
