defmodule ElixirStream.MixProject do
  use Mix.Project

  def project do
    [
      app: :elixir_stream,
      version: File.read!("VERSION") |> String.trim(),
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      compilers: [:phoenix, :gettext] ++ Mix.compilers(),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: [
        elixirstream: [
          steps: [:assemble, :tar],
          path: "releases/artifacts",
          include_executables_for: [:unix],
          include_erts: true,
          applications: [runtime_tools: :permanent]
        ]
      ]
    ]
  end

  def application do
    [
      mod: {ElixirStream.Application, []},
      extra_applications: [:logger, :runtime_tools] ++ extra_applications(Mix.env())
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp extra_applications(:test), do: []
  defp extra_applications(_), do: [:os_mon]

  defp deps do
    [
      {:bamboo, "~> 2.0"},
      {:ecto_sql, "~> 3.4", override: true},
      {:ecto_psql_extras, "~> 0.2"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_s3, "~> 2.0"},
      {:finch, "~> 0.6"},
      {:gettext, "~> 0.11"},
      {:guardian, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:makeup, "~> 1.0"},
      {:makeup_elixir, "~> 0.14"},
      {:mime, "~> 1.2"},
      {:oauther, "~> 1.1"},
      {:oban, "~> 2.5"},
      {:phoenix, "~> 1.5"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 2.11"},
      {:phoenix_live_dashboard, "~> 0.4"},
      {:phoenix_live_view, "~> 0.15.0"},
      {:plug_cowboy, "~> 2.0"},
      {:postgrex, ">= 0.0.0"},
      {:quarto, "~> 1.0"},
      {:sentry, "~> 8.0"},
      {:sweet_xml, "~> 0.6"},
      {:telemetry_metrics, "~> 0.4"},
      {:telemetry_poller, "~> 0.4"},
      {:ueberauth, "~> 0.6"},
      {:ueberauth_github, "~> 0.7"},
      {:ueberauth_twitter, "~> 0.3"},
      # Test/Dev
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_machina, "~> 2.6", only: :test},
      {:floki, ">= 0.27.0", only: :test},
      {:phoenix_live_reload, "~> 1.2", only: :dev}
    ]
  end

  defp aliases do
    [
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      outdated: ["hex.outdated", "cmd npm --prefix assets outdated || true"],
      setup: ["deps.get", "ecto.setup", "cmd npm install --prefix assets"],
      test: ["ecto.create --quiet", "ecto.migrate --quiet", "test"]
    ]
  end
end
