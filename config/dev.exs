use Mix.Config

config :job_webserver, JobWebserver.Repo,
  adapter: Ecto.Adapters.MySQL,
  database: "job_dev",
  username: "root",
  password: "mysql",
  hostname: "localhost",
  pool_size: 10
