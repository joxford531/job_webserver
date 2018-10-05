# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :job_webserver, http_port: 4000

config :logger, level: :debug

config :swarm, node_blacklist: ["debug@127.0.0.1"], debug: false

config :libcluster,
  topologies: [
    example: [
      # The selected clustering strategy. Required.
      strategy: Cluster.Strategy.Epmd,
      # Configuration for the provided strategy. Optional.
      config: [hosts: [:"node1@127.0.0.1", :"node2@127.0.0.1", :"node3@127.0.0.1"]]
    ]
  ]

config :job_webserver, :ecto_repos, [JobWebserver.Repo]

config :job_webserver, JobWebserver.Repo,
  adapter: Ecto.Adapters.MySQL,
  database: "job_dev",
  username: "root",
  password: "mysql",
  hostname: "localhost",
  pool_size: 10


import_config "#{Mix.env()}.exs"
# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :job_webserver, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:job_webserver, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env()}.exs"
