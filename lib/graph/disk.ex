defmodule Graph.Disk do
  @moduledoc false
  use GenServer

  # API
  def start_link(path) do
    GenServer.start_link(__MODULE__, path, name: Graph.Disk)
  end

  def update_vertex(vertex_index, vertex_state) do
    GenServer.cast(Graph.Disk, {:udate_vertex, vertex_index, vertex_state})
  end

  # Callbacks
  def init(path) do
    json =
      if File.exists?(path) do
        {:ok, json} = File.read(path)
        Jason.decode!(json)
      else
        %{}
      end

    {:ok, {path, json}}
  end

  def handle_cast({:udate_vertex, vertex_index, vertex_state}, {path, json}) do
    json = Map.put(json, vertex_index, vertex_state)
    update_json(path, json)
    {:noreply, {path, json}}
  end

  defp update_json(path, json) do
    backup_path = "#{path}.1"
    {:ok, file} = File.open(backup_path, [:write])
    IO.binwrite(file, Jason.encode!(json))
    File.close(file)

    File.rm(path)
    {:ok, file} = File.open(path, [:write])
    IO.binwrite(file, Jason.encode!(json))

    File.rm(backup_path)
  end
end
