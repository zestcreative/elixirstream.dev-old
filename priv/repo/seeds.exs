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

if Application.get_env(:elixir_stream, :app_env) == :dev do
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
end

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
  twitter_status_id: "1367172927624384513",
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
  twitter_status_id: "1369709645993017344",
  published_at: DateTime.new!(Date.new!(2021, 03, 10), Time.new!(13, 0, 0, 0)),
  contributor_id: akoutmos.id
})

Repo.insert!(%Tip{
  title: "Simple stream data processing",
  approved: true,
  description: """
  The Enum and Stream modules complement each other quite nicely and can be used for easy and effective data processing. Take a look at how you can stream process a CSV file!
  """,
  code: """
  # $ cat ./expenses.csv
  # # System76 Lemur Pro,1499.99
  # # MacBook AIr,1999.99
  # # AMD Ryzen 3950x,749.99A
  # ...

  iex> "./expenses.csv" |>
  ...> File.stream!() |>
  ...> Stream.map(fn line ->
  ...>   line |>
  ...>   String.trim() |>
  ...>   String.split(",") |>
  ...>   Enum.at(1) |>
  ...>   String.to_float()
  ...> end |>
  ...> Enum.sum()
  4249.97
  """,
  twitter_status_id: "1370434414564499456",
  published_at: DateTime.new!(Date.new!(2021, 03, 12), Time.new!(13, 0, 0, 0)),
  contributor_id: akoutmos.id
})

Repo.insert!(%Tip{
  title: "Oban - Replace Args",
  approved: true,
  description: """
  Did you know that you can selectively replace args when inserting a unique job? With `replace_args`, when an existing
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

Repo.insert!(%Tip{
  title: "Oban - Unique Keys",
  approved: true,
  description: """
  By default, job uniqueness is based on teh queue, state, and args. Did you know you can restrict checking args to only a subset of keys?

  https://hexdocs.pm/oban/Oban.html#module-unique-jobs
  """,
  code: """
  # Configure uniqueness only based on the id :id field
  defmodule MyApp.BusinessWorker do
    use Oban.Worker, unique: [keys: [:id]]

    # ...
  end

  # With an existing job:
  %{id: 1, type: "business", url: "https://example.com"}
  |> MyApp.BusinessWorker.new()
  |> Oban.insert()

  # Inserting another job with a different type won't work
  %{id: 1, type: "solo", url: "https://example.com"}
  |> MyApp.BusinessWorker.new()
  |> Oban.insert()

  # Inserting another job with a different type won't work
  %{id: 2, type: "business", url: "https://example.com"}
  |> MyApp.BusinessWorker.new()
  |> Oban.insert()
  """,
  twitter_status_id: "1369411161205207045",
  published_at: DateTime.new!(Date.new!(2021, 03, 9), Time.new!(17, 13, 0, 0)),
  contributor_id: sorentwo.id
})

Repo.insert!(%Tip{
  title: "Oban - Priority",
  approved: true,
  description: """
  Did you know that you can prioritize or de-prioritize jobs in a queue by setting a priority from 0-3? Rather than executing in the order they were scheduled, higher priority jobs execute first.

  https://hexdocs.pm/oban/Oban.html#module-prioritizing-jobs
  """,
  code: """
  # Configure uniqueness only based on the id :id field
  defmodule MyApp.BusinessWorker do
    use Oban.Worker, queue: :events, priority: 1

    # ...
  end

  # Manually set a higher priority for a job on the "mega" plan
  MyApp.BusinessWorker.new(%{id: 1, plan: "mega"}, priority: 0)

  # Manually set a lower priority for a job on the "free" plan
  MyApp.BusinessWorker.new(%{id: 1, plan: "free"}, priority: 3)
  """,
  twitter_status_id: "1365037078384414722",
  published_at: DateTime.new!(Date.new!(2021, 2, 25), Time.new!(15, 32, 0, 0)),
  contributor_id: sorentwo.id
})

Repo.insert!(%Tip{
  title: "Oban - Initially Paused",
  approved: true,
  description: """
  In the queue-pause saga, did you know you can start a queue in the paused state? Passing `paused: true` as a queue option prevents the queue from processing jobs when it starts.

  https://hexdocs.pm/oban/Oban.html#start_link/1-primary-options
  """,
  code: """
  # In a blue-green deployment, it may be necessary to start queues when the node
  # boots yet prevent them from processing jobs until the node is rotated into
  # use.
  config :my_app, Oban,
    queues: [
      mailer: 10,
      alpha: [limit: 10, paused: true],
      gamma: [limit: 10, paused: true],
      omega: [limit: 10, paused: true]
    ],
  ...

  # Once the app boots, tell each queue to resume processing:
  for queue <- [:alpha, :gamma, :omega] do
    Oban.resume_queue(queue: queue)
  end
  """,
  twitter_status_id: "1364265804347432964",
  published_at: DateTime.new!(Date.new!(2021, 2, 23), Time.new!(12, 28, 0, 0)),
  contributor_id: sorentwo.id
})

Repo.insert!(%Tip{
  title: "Oban - Graceful Shutdown",
  approved: true,
  description: """
  Did you know that when an app shuts down Oban pauses all queues and waits for jobs to finish? The time is configurable and defaults to 15 seconds, short enough for most deployments.

  https://hexdocs.pm/oban/Oban.html#start_link/1-twiddly-options
  """,
  code: """
  # Change the default to 30 seconds
  config :my_app, Oban,
    repo: MyApp.Repo,
    queues: [default: 10]
    shutdown_grace_period: :timer.seconds(30)

  # Wait up to an hour for long running jobs in a blue-green style deply
  config :my_app, Oban,
    shutdown_grace_period: :timer.minutes(60)
  """,
  twitter_status_id: "1362436004175560705",
  published_at: DateTime.new!(Date.new!(2021, 2, 18), Time.new!(11, 17, 0, 0)),
  contributor_id: sorentwo.id
})

Repo.insert!(%Tip{
  title: "Oban - Pausing Queues",
  approved: true,
  description: """
  Did you know that you can pause a queue to stop it from processing more jobs? Calling `pause_queue/2` allows executing jobs to keep running while preventing a queue from fetching new jobs.

  https://hexdocs.pm/oban/Oban.html#pause_queue/2
  """,
  code: """
  # Pause all instances of the :default queue across all nodes
  Oban.pause_queue(queue: :default)

  # Pause only the local instance, leaving instances on any other nodes running
  Oban.pause_queue(queue: :default, local_only: true)

  # Queues are namespaced by prefix, so you can pause the :default queue for an
  # isolated supervisor
  Oban.pause_queue(MyApp.A.Oban, queue: :default)
  """,
  twitter_status_id: "1361743616121659395",
  published_at: DateTime.new!(Date.new!(2021, 2, 16), Time.new!(13, 25, 0, 0)),
  contributor_id: sorentwo.id
})

Repo.insert!(%Tip{
  title: "Oban - Recording Errors",
  approved: true,
  description: """
  Did you know that errors are recorded in the database when a job fails? A job's `errors` field contains a list of the time, attempt and a formatted error message for each failed attempt.

  https://hexdocs.pm/oban/Oban.Job.html#t:errors/0
  """,
  code: """
  # Errors look like this, where `at` is a UTC timestamp and `error` is the blamed
  # and formatted error message.
  [
    %{
      "at" => "2021-02-11T17:01:13.517233Z",
      "attempt" => 1,
      "error" => "** (RuntimeError) Something went wrong!\\n..."
    }
  ]

  # Check the errors for a job with multiple attempts to see if it failed before
  # or it was snoozed.
  def perform(%Job{attempt: attempt, errors: errors}) when attempt > 1 do
    case errors do
      [%{"error" => error} | _] ->
        IO.puts "This job failed with the error:\\n\\n" <> error
      [] ->
        IO.puts "This job snoozed, it doesn't have any errors"
    end

    :ok
  end
  """,
  twitter_status_id: "1359912269791035392",
  published_at: DateTime.new!(Date.new!(2021, 2, 11), Time.new!(12, 08, 0, 0)),
  contributor_id: sorentwo.id
})
