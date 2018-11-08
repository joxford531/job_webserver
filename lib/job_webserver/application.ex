defmodule JobWebserver.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      {
        Cluster.Supervisor,
        [Application.get_env(:libcluster, :topologies), [name: __MODULE__.ClusterSupervisor]]
      },
      JobWebserver.Cache,
      JobWebserver.Repo,
      Plug.Adapters.Cowboy.child_spec(scheme: :http, plug: JobWebserver.Router, options: [port: Application.fetch_env!(:job_webserver, :http_port)]),
      {JobWebserver.CheckJobs, []}
    ]
    opts = [strategy: :one_for_one, name: JobWebserver.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
