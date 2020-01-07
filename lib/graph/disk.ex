defmodule ExGraph.Disk do
  @moduledoc false
  use GenServer

  # API
  def start_link(path: path, opts: opts) do
    GenServer.start_link(__MODULE__, path, opts)
  end

  def update_vertex(vertex_name, vertex_state) do
    vertex_name =
      if is_atom(vertex_name) do
        to_string(vertex_name)
      else
        vertex_name
      end

    GenServer.cast(ExGraph.Disk, {:udate_vertex, vertex_name, vertex_state})
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

    load_vertices(Map.to_list(json))
    {:ok, {path, json}}
  end

  def handle_cast({:udate_vertex, vertex_name, vertex_state}, {path, json}) do
    json = Map.put(json, vertex_name, vertex_state)
    update_json(path, json)
    {:noreply, {path, json}}
  end

  defp update_json(path, json) do
    backup_path = "#{path}.1"
    File.rm(backup_path)
    {:ok, file} = File.open(backup_path, [:write])
    IO.binwrite(file, Jason.encode!(json))
    File.close(file)

    File.rm(path)
    {:ok, file} = File.open(path, [:write])
    IO.binwrite(file, Jason.encode!(json))
  end

  # Utils
  def load_vertices(vertices) do
    Enum.each(vertices, fn {_index, state} ->
      state |> Map.new(fn {k, v} -> {String.to_atom(k), v} end) |> ExGraph.Vertex.new_vertex()
    end)
  end
end
