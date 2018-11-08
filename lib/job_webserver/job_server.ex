defmodule JobWebserver.JobServer do
  use GenServer, restart: :temporary

  def start_link({job_name, %{"site" => _, "unitCode" => _, "time" => _, "command" => _} = job}) do
    Swarm.register_name({__MODULE__, job_name}, __MODULE__, :start, [{job_name, job}])
  end

  def start({job_name, job}) do
    GenServer.start_link(__MODULE__, {job_name, job})
  end

  def init({job_name, job}) do
    timer_ref = schedule_job(job)
    store_job(job_name, job)
    {
      :ok,
      {job_name, job, timer_ref}
    }
  end

  def kill_node_jobs() do
    Swarm.registered()
    |> Stream.map(fn {{_,_}, pid} -> pid end)
    |> Stream.filter(fn pid -> node(pid) == Node.self() end)
    |> Enum.each(fn pid -> Process.exit(pid, :remove) end)
  end

  def remove_job(pid) do
    GenServer.cast(pid, {:terminate})
  end

  def whereis(job_name) do
    case Swarm.whereis_name({__MODULE__, job_name}) do
      :undefined -> nil
      _ -> job_name # returns a pid if registered, but we want to return job_name
    end
  end

  def whereis_pid(job_name) do
    case Swarm.whereis_name({__MODULE__, job_name}) do
      :undefined -> nil
      pid -> pid
    end
  end

  def handle_cast({:terminate}, {job_name, job, timer_ref}) do
    Swarm.unregister_name({__MODULE__, job_name})
    Process.cancel_timer(timer_ref)
    delete_job(job_name)
    {:stop, :normal, {job_name, job, timer_ref}}
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

  def handle_info(:perform, {job_name, job, timer_ref}) do
    IO.puts("firing job! - #{job_name}")

    delete_job(job_name)

    {:stop, :normal, {job_name, job, timer_ref}}
  end

  defp delete_job(job_name) do
    JobWebserver.Database.find_job(job_name)
    |> JobWebserver.Database.delete_job()
  end

  defp schedule_job(%{"site" => _, "unitCode" => _, "time" => _, "command" => _} = job) do
    send_after =
      job["time"]
      |> Timex.parse!("{ISO:Extended}")
      |> Timex.diff(Timex.now, :milliseconds)

    Process.send_after(self(), :perform, send_after)
  end

  defp store_job(job_name, %{"site" => _, "unitCode" => _, "time" => _, "command" => _} = job) do
    %JobWebserver.Job{
      trigger_name: job_name,
      site: job["site"],
      unit_code: job["unitCode"],
      command: job["command"],
      time: Timex.parse!(job["time"], "{ISO:Extended}")
    } |> JobWebserver.Database.store_job()
  end
end
