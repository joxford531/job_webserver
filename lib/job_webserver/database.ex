defmodule JobWebserver.Database do
  def store_job(%JobWebserver.Job{} = job) do
    JobWebserver.Repo.insert(job, on_conflict: :nothing) # don't return an error if there is a unique key conflict
  end

  def find_job(job_name) when is_bitstring(job_name) do
    JobWebserver.Job
    |> JobWebserver.Repo.get_by(trigger_name: job_name)
  end

  def delete_job(%JobWebserver.Job{} = job) do
    JobWebserver.Repo.delete(job)
  end
end
