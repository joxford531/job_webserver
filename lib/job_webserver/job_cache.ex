defmodule JobWebserver.Cache do
  def start_link() do
    DynamicSupervisor.start_link(name: __MODULE__, strategy: :one_for_one)
  end

  # must define child_spec when you want this to be a supervised process and you don't use
  # Genserver
  def child_spec(_) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :supervisor
    }
  end

  def create_server_process(%{"site" => _, "unitCode" => _, "time" => _, "command" => _} = job) do
    job_name = hash_job_name(job)
    existing_process(job_name) || new_process(job_name, job)
  end

  def update_server_process(existing_job_name, %{"site" => _, "unitCode" => _, "time" => _, "command" => _} = new_job) do
    case JobWebserver.JobServer.whereis_pid(existing_job_name) do
      nil -> {:error, "no such job exists"}
      pid -> update_process(pid, new_job)
    end
  end

  def server_healthy?(job_name) do
    case JobWebserver.JobServer.whereis(job_name) do # if we get a response then Swarm is properly connected on node
      _ -> true
    end
  end

  defp existing_process(job_name) do
    JobWebserver.JobServer.whereis(job_name) # if not registered will return nil which is treated as falsy
  end

  defp new_process(job_name, job) do
    case DynamicSupervisor.start_child(
      __MODULE__,
    {JobWebserver.JobServer, {job_name, job}}
    ) do
      {:ok, _} -> job_name
      {:error, {:already_registered, _}} -> job_name
      {:error, {:invalid_return, _}} -> {:error, "time not valid or in the past"}
    end
  end

  defp update_process(pid, new_job) do
    JobWebserver.JobServer.remove_job(pid)
    new_process(hash_job_name(new_job), new_job)
  end

  defp hash_job_name(body) do
    time =
      body["time"]
      |> Timex.parse!("{ISO:Extended:Z}")
      |> Timex.format!("{ISO:Extended:Z}")
    # we're converting to zulu time so that DB read job hashes the same since time is stored in UTC in DB
    name = body["site"] <> body["unitCode"] <> body["command"] <> time
    Base.encode16(:crypto.hash(:sha256, name))
  end
end
