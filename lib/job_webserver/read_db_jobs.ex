defmodule JobWebserver.CheckJobs do
  use Task

  def start_link(_arg) do
    Task.start_link(__MODULE__, :loop, [])
  end

  def loop() do
    # cluster wide lock that will retry a small number of times
    Process.sleep(:timer.seconds(60))
    :global.trans({:db_job_check, self()}, &run/0, Node.list([:this, :visible]), 3)
    loop()
  end

  def run() do
    time_elapsed =
      fn ->
        get_all_jobs()
        |> check_job_registered()
      end
      |> :timer.tc
      |> elem(0)
      |> Kernel./(1_000)

    IO.puts("Read DB Jobs finished in #{round(time_elapsed)}ms")
    check_swarm_jobs()
  end

  defp get_all_jobs() do
    JobWebserver.Job
    |> JobWebserver.Repo.all()
  end

  defp check_job_registered(jobs) do
    jobs
    |> Enum.each(&register_job/1)
  end

  defp register_job(%JobWebserver.Job{} = job) do
    mapped = %{
      "site" => job.site,
      "unitCode" => job.unit_code,
      "time" => Timex.format!(job.time, "{ISO:Extended}"),
      "command" => job.command
    }
    JobWebserver.Cache.create_server_process(mapped)
  end

  defp check_swarm_jobs() do
    Swarm.registered()
    |> Stream.filter(fn {{_, _}, pid} -> !Enum.member?(Node.list([:this, :visible]), node(pid)) end)
    |> Enum.each(fn {{module, job_name}, _} -> Swarm.unregister_name({module, job_name}) end)
  end
end
