defmodule ExGraph.Vertex do
  @moduledoc false
  use GenServer, restart: :temporary

  # API
  def new_vertex(%{index: index, labels: labels, keys: keys}) do
    new_vertex(index, labels, keys)
  end

  def new_vertex(index, labels \\ [], keys \\ %{}) do
    name = index_to_name(index)

    {:ok, _ref} =
      DynamicSupervisor.start_child(
        ExGraph.VertexSupervisor,
        {__MODULE__, index: index, labels: labels, keys: keys, opts: [name: name]}
      )
  end

  def start_link(index: index, labels: labels, keys: keys, opts: opts) do
    GenServer.start_link(__MODULE__, {index, labels, keys}, opts)
  end

  def add_edge(vertex_index, edge_index) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:add_edge, edge_index})
  end

  def remove_edge(vertex_index, edge_index) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:remove_edge, edge_index})
  end

  def edges(vertex_index) do
    name = index_to_name(vertex_index)
    GenServer.call(name, :edges)
  end

  def add_label(vertex_index, label) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:add_label, label})
  end

  def remove_label(vertex_index, label) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:remove_label, label})
  end

  def labels(vertex_index) do
    name = index_to_name(vertex_index)
    GenServer.call(name, :labels)
  end

  def add_key(vertex_index, key, value) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:add_key, key, value})
  end

  def remove_key(vertex_index, key) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:remove_key, key})
  end

  def keys(vertex_index) do
    name = index_to_name(vertex_index)
    GenServer.call(name, :keys)
  end

  # Callbacks
  @impl true
  def init({index, labels, keys}) do
    state = %{:index => index, :edges => [], :labels => labels, :keys => keys}
    persist_to_disk(index, state)

    ExGraph.Indexer.add_index(:vertex_index, index, nil)
    Enum.each(labels, fn l -> ExGraph.Indexer.add_index(:label, l, index) end)
    {:ok, state}
  end

  @impl true
  def handle_call(:edges, _from, state = %{edges: edges}) do
    {:reply, edges, state}
  end

  @impl true
  def handle_call(:labels, _from, state = %{labels: labels}) do
    {:reply, labels, state}
  end

  @impl true
  def handle_call(:keys, _from, state = %{keys: keys}) do
    {:reply, keys, state}
  end

  @impl true
  def handle_cast({:add_edge, edge_index}, state = %{index: index, edges: edges}) do
    Process.monitor(index_to_name(edge_index))
    edges = [edge_index | edges]
    state = %{state | edges: edges}
    persist_to_disk(index, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove_edge, edge_index}, state = %{index: index, edges: edges}) do
    Process.demonitor(index_to_name(edge_index))
    edges = List.delete(edges, edge_index)
    state = %{state | edges: edges}
    persist_to_disk(index, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_label, label}, state = %{index: index, labels: labels}) do
    labels = [label | labels]
    ExGraph.Indexer.add_index(:label, label, index)
    state = %{state | labels: labels}
    persist_to_disk(index, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove_label, label}, state = %{index: index, labels: labels}) do
    labels = List.delete(labels, label)
    ExGraph.Indexer.remove_index(:label, label, index)
    state = %{state | labels: labels}
    persist_to_disk(index, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_key, key, value}, state = %{index: index, keys: keys}) do
    keys = Map.put(keys, key, value)
    state = %{state | keys: keys}
    persist_to_disk(index, state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove_key, key}, state = %{index: index, keys: keys}) do
    keys = Map.delete(keys, key)
    state = %{state | keys: keys}
    persist_to_disk(index, state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, state = %{index: index, edges: edges}) do
    name = elem(pid, 0)
    edges = List.delete(edges, name_to_index(name))
    state = %{state | edges: edges}
    persist_to_disk(index, state)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Utils
  defp index_to_name(index) do
    String.to_atom("ExGraph.Vertex.#{index}")
  end

  defp name_to_index(name) do
    to_string(name)
    |> String.split(".")
    |> List.last()
  end

  defp persist_to_disk(index, state) do
    ExGraph.Disk.update_vertex(index, state)
  end
end
