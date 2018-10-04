defmodule JobWebserver.Database do
  def store_job(%JobWebserver.Job{} = job) do
    JobWebserver.Repo.insert(job)
  end

  def find_job(job_name) when is_bitstring(job_name) do
    JobWebserver.Job
    |> JobWebserver.Repo.get_by(trigger_name: job_name)
  end

  def delete_job(%JobWebserver.Job{} = job) do
    JobWebserver.Repo.delete(job)
  end
end
