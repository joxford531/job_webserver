defmodule JobWebserver.Repo.Migrations.CreateJobs do
  use Ecto.Migration

  def change do
    create table(:jobs) do
      add(:trigger_name, :char, size: 64, null: false)
      add(:site, :string, null: false)
      add(:unit_code, :string, null: false)
      add(:command, :string, null: false)
      add(:time, :naive_datetime, null: false)
    end
    create unique_index(:jobs, :trigger_name)
  end
end
