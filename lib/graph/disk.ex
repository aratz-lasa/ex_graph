defmodule ExGraph.Disk do
  @moduledoc false
  use GenServer

  import ExGraph.Utils

  # API
  def start_link(path: path, opts: opts) do
    GenServer.start_link(__MODULE__, path, opts)
  end

  def update_vertex(vertex_name, vertex_state) do
    vertex_name = atom_to_string(vertex_name)
    GenServer.cast(ExGraph.Disk, {:udate_vertex, vertex_name, vertex_state})
  end

  def update_edges(vertex_name, vertex_edges) do
    vertex_name = atom_to_string(vertex_name)
    GenServer.cast(ExGraph.Disk, {:update_edges, vertex_name, vertex_edges})
  end

  # Callbacks
  def init(path) do
    db =
      if File.exists?(path) do
        {:ok, db} = File.read(path)
        db |> Jason.decode!() |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      else
        %{:vertexes => %{}, :edges => %{}}
      end

    load_vertexes(Map.to_list(db.vertexes))
    load_edges(Map.to_list(db.edges))
    {:ok, {path, db}}
  end

  def handle_cast({:udate_vertex, vertex_name, vertex_state}, {path, db}) do
    vertexes = Map.put(db.vertexes, vertex_name, vertex_state)
    db = Map.put(db, :vertexes, vertexes)
    update_db(path, db)
    {:noreply, {path, db}}
  end

  def handle_cast({:update_edges, vertex_name, vertex_edges}, {path, db}) do
    edges = Map.put(db.edges, vertex_name, vertex_edges)
    db = Map.put(db, :edges, edges)
    update_db(path, db)
    {:noreply, {path, db}}
  end

  defp update_db(path, db) do
    backup_path = "#{path}.1"
    File.rename(path, backup_path)

    {:ok, file} = File.open(path, [:write])
    IO.binwrite(file, Jason.encode!(db))
  end

  # Utils
  defp load_vertexes(vertexes) do
    Enum.each(vertexes, fn {_index, state} ->
      state |> Map.new(fn {k, v} -> {String.to_atom(k), v} end) |> ExGraph.Vertex.new_vertex()
    end)
  end

  defp load_edges(edges) do
    Enum.each(edges, fn {vertex_name, vertex_edges} ->
      ExGraph.Vertex.add_edges(name_to_index(vertex_name), vertex_edges)
    end)
  end

  defp atom_to_string(name) do
    if is_atom(name) do
      to_string(name)
    else
      name
    end
  end
end
