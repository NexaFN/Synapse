defmodule Synapse.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Synapse.Tracker, []},
      {Task.Supervisor, name: Synapse.TaskSupervisor},
      {Bandit, plug: Synapse.Router, scheme: :http, port: 4040}
    ]

    opts = [strategy: :one_for_one, name: Synapse.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
 