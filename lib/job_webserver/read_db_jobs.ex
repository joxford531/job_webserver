defmodule JobWebserver.ReadDbJobs do
  use Task

  def start_link(_arg) do
    Task.start_link(__MODULE__, :start, [])
  end

  def start() do
    # cluster wide lock that will retry a small number of times
    :global.trans({:server_startup, self()}, &run/0, Node.list([:this, :visible]), 3)
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
    JobWebserver.Cache.server_process(job.trigger_name, mapped)
  end
end
