defmodule ExGraph.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, :ok, opts)
  end

  @impl true
  def init(:ok) do
    children = [
      {ExGraph.Indexer, opts: [name: ExGraph.Indexer]},
      {DynamicSupervisor, name: ExGraph.VertexSupervisor, strategy: :one_for_one},
      {ExGraph.Disk, path: "graph.db", opts: [name: ExGraph.Disk]}
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
