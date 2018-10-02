defmodule JobWebserver.JobServer do
  use GenServer

  def start_link({job_name, fire_time}) do
    IO.puts("Starting Job - #{job_name}")
    Swarm.register_name({__MODULE__, job_name}, __MODULE__, :start, [{job_name, fire_time}])
  end

  def start({job_name, fire_time}) do
    GenServer.start_link(__MODULE__, {job_name, fire_time})
  end

  def init({job_name, fire_time}) do
    schedule_job(fire_time)
    {
      :ok,
      {job_name, fire_time}
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

  def handle_info(:perform, state) do
    IO.puts("firing job!")
    {:noreply, state}
  end

  defp schedule_job(fire_time) do
    send_after =
      fire_time
      |> Timex.parse!("{ISO:Extended}")
      |> Timex.diff(Timex.now, :milliseconds)

    Process.send_after(self(), :perform, send_after)
  end
end
