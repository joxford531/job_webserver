defmodule JobWebserver.MixProject do
  use Mix.Project

  def project do
    [
      app: :job_webserver,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      preferred_cli_env: [release: :prod]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :cowboy, :plug, :poison, :timex, :timex_ecto, :runtime_tools],
      mod: {JobWebserver.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:plug_cowboy, "~> 1.0"},
      {:plug, "~> 1.4"},
      {:libcluster, "~> 3.0"},
      {:swarm, "~> 3.3"},
      {:ecto, "~> 2.2.10"},
      {:mariaex, "~> 0.8.2"},
      {:poison, "~> 3.1"},
      {:timex, "~> 3.1"},
      {:timex_ecto, "~> 3.0"},
      {:distillery, "~> 2.0"}
    ]
  end
end
