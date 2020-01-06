defmodule ExGraph do
  @moduledoc """
  Documentation for ExGraph.
  """
  use Application

  @impl true
  def start(_type, _args) do
    ExGraph.Supervisor.start_link(name: ExGraph.Supervisor)
  end
end
