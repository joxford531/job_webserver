defmodule JobWebserver.JobServer do
  use GenServer

  def start_link({job_name, %{"site" => _, "unitCode" => _, "time" => _, "command" => _} = job}) do
    store_job(job_name, job)
    Swarm.register_name({__MODULE__, job_name}, __MODULE__, :start, [{job_name, job}])
  end

  def start({job_name, job}) do
    GenServer.start_link(__MODULE__, {job_name, job})
  end

  def init({job_name, job}) do
    schedule_job(job_name, job)
    IO.puts("init callback")
    {
      :ok,
      {job_name, job["time"]}
    }
  end

  def whereis(job_name) do
    case Swarm.whereis_name({__MODULE__, job_name}) do
      :undefined -> nil
      _ -> job_name # returns a pid if registered, but we want to return job_name
    end
  end

  def handle_cast({:swarm, :end_handoff, _old_state}, state) do
    IO.puts("end handoff")
    {:noreply, state}
  end

  def handle_cast({:swarm, :resolve_conflict, _other_state}, state) do
    {:noreply, state}
  end

  def handle_call({:swarm, :begin_handoff}, _from, state) do
    IO.puts("Begin handoff")
    {:reply, {:resume, state}, state}
  end

  def handle_info({:swarm, :die}, state) do
    {:stop, :shutdown, state}
  end

  def handle_info(:perform, {job_name, fire_time}) do
    IO.puts("firing job!")

    JobWebserver.Database.find_job(job_name)
    |> JobWebserver.Database.delete_job()

    {:stop, :normal, {job_name, fire_time}}
  end

  defp schedule_job(job_name, %{"site" => _, "unitCode" => _, "time" => _, "command" => _} = job) do
    IO.puts("Scheduling Job - #{job_name}")

    send_after =
      job["time"]
      |> Timex.parse!("{ISO:Extended}")
      |> Timex.diff(Timex.now, :milliseconds)

    Process.send_after(self(), :perform, send_after)
  end

  defp store_job(job_name, %{"site" => _, "unitCode" => _, "time" => _, "command" => _} = job) do
    IO.puts("Persist Job to DB - #{job_name}")

    %JobWebserver.Job{
      trigger_name: job_name,
      site: job["site"],
      unit_code: job["unitCode"],
      command: job["command"],
      time: Timex.parse!(job["time"], "{ISO:Extended}")
    } |> JobWebserver.Database.store_job()
  end
end
