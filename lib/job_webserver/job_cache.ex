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

  def kill_node_jobs() do
    JobWebserver.JobServer.kill_node_jobs()
  end

  def server_process(job_name, %{"site" => _, "unitCode" => _, "time" => _, "command" => _} = job) do
    existing_process(job_name) || new_process(job_name, job)
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
end
