defmodule JobWebserver.Job do
  use Ecto.Schema

  schema "jobs" do
    field :trigger_name, :string
    field :site, :string
    field :unit_code, :string
    field :command, :string
    field :time, Timex.Ecto.DateTime
  end
end
