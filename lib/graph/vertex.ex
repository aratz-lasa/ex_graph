defmodule Graph.Vertex do
  @moduledoc false
  use GenServer

  # API
  def start_link(index, labels \\ [], keys \\ %{}) do
    name = index_to_name(index)
    GenServer.start_link(__MODULE__, {index, labels, keys}, [name: name])
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
    Graph.Indexer.add_index(:vertex_index, index, nil)
    Enum.each(labels, fn l -> Graph.Indexer.add_index(:label, l, index) end)
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
  def handle_cast({:add_edge, edge_index}, state = %{edges: edges}) do
    edges = [edge_index | edges]
    {:noreply, %{state | edges: edges}}
  end

  @impl true
  def handle_cast({:remove_edge, edge_index}, state = %{edges: edges}) do
    edges = List.delete(edges, edge_index)
    {:noreply, %{state | edges: edges}}
  end

  @impl true
  def handle_cast({:add_label, label}, state = %{index: index, labels: labels}) do
    labels = [label | labels]
    Graph.Indexer.add_index(:label, label, index)
    {:noreply, %{state | labels: labels}}
  end

  @impl true
  def handle_cast({:remove_label, label}, state = %{index: index, labels: labels}) do
    labels = List.delete(labels, label)
    Graph.Indexer.remove_index(:label, label, index)
    {:noreply, %{state | labels: labels}}
  end

  @impl true
  def handle_cast({:add_key, key, value}, state = %{keys: keys}) do
    keys = Map.put(keys, key, value)
    {:noreply, %{state | keys: keys}}
  end

  @impl true
  def handle_cast({:remove_key, key}, state = %{keys: keys}) do
    keys = Map.delete(keys, key)
    {:noreply, %{state | keys: keys}}
  end

  # Utils
  defp index_to_name(index) do
    String.to_atom("Graph.Edge.#{index}")
  end
end
