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

demouser =
  Repo.insert!(%User{
    source: :github,
    source_id: "123123",
    name: "Demo User",
    avatar:
      "https://images.unsplash.com/photo-1598886221321-26aa46a669f2?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=face&w=1024&h=1024&q=80&",
    username: "demo_user",
    twitter: "demouser"
  })

akoutmos =
  Repo.insert!(%User{
    source: :github,
    source_id: "4753634",
    name: "Alexander Koutmos",
    avatar: "https://avatars.githubusercontent.com/u/4753634?v=4",
    username: "akoutmos",
    twitter: "akoutmos"
  })

sorentwo =
  Repo.insert!(%User{
    source: :github,
    source_id: "270831",
    name: "Parker Selbert",
    avatar: "https://avatars.githubusercontent.com/u/270831?v=4",
    username: "sorentwo",
    twitter: "sorentwo"
  })

for i <- 0..50 do
  Repo.insert!(%Tip{
    title: "Test Title #{i}",
    approved: false,
    description: "Test description foo bar baz que qux #{i}",
    code: """
    iex> IO.puts "WOWZERS"
    #=> "WOWZERS"
    """,
    published_at: DateTime.utc_now() |> DateTime.add(-:rand.uniform(10000)),
    contributor_id: demouser.id,
    upvote_count: i
  })
end

Repo.insert!(%Tip{
  title: "Tracing GenServer execution",
  approved: true,
  twitter_status_id: "1368984861776568322",
  description: """
  The BEAM has some of the best observability tools built right into the runtime. Right down to tracing individual GenServer process execution flow!
  """,
  code: """
  iex> {:ok, agent} = Agent.start_link fn -> [] end
  {:ok, #PID<0.112.0>}

  iex> :sys.trace(agent, true)
  :ok

  iex> Agent.get_and_update(agent, fn state -> {state, [1 | state]} end)
  *DBG* <0.112.0> got call {get_and_update, #Fun<erl_eval.44.12345123} from <0.110.0>
  *DBG* <0.112.0> sent [] to <0.110.0>, new state [1]
  []

  iex> Agent.get(agent, fn state -> state end)
  *DBG* <0.112.0> got call {get, #Fun<erl_eval.44.12345124} from <0.110.0>
  *DBG* <0.112.0> sent [1] to <0.110.0>, new state [1]
  [1]

  iex> :sys.trace(agent, false)
  :ok

  iex> Agent.get(agent, fn state -> state end)
  [1]
  """,
  published_at: DateTime.new!(Date.new!(2021, 03, 8), Time.new!(13, 0, 0, 0)),
  contributor_id: akoutmos.id
})

Repo.insert!(%Tip{
  title: "The string concat operator",
  approved: true,
  twitter_status_id: "1367172927624384513",
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
  published_at: DateTime.new!(Date.new!(2021, 3, 3), Time.new!(13, 0, 0, 0)),
  contributor_id: akoutmos.id
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
  contributor_id: akoutmos.id
})

Repo.insert!(%Tip{
  title: "Oban - Replace Args",
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
  twitter_status_id: "1367579427169853443",
  published_at: DateTime.new!(Date.new!(2021, 03, 4), Time.new!(15, 55, 0, 0)),
  contributor_id: sorentwo.id
})

Repo.insert!(%Tip{
  title: "Oban - Unique jobs",
  approved: true,
  description: """
  Did you know that Oban lets you specify constraints to prevent enqueuing duplicate jobs? Uniqueness is enforced as jobs are inserted, dynamically and atomically.

  https://hexdocs.pm/oban/Oban.html#module-unique-jobs
  """,
  code: """
  # Configure 60 seconds of uniqueness within the worker
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
  twitter_status_id: "1366846491466285059",
  published_at: DateTime.new!(Date.new!(2021, 03, 2), Time.new!(15, 22, 0, 0)),
  contributor_id: sorentwo.id
})
