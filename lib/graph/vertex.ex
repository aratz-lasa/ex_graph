defmodule ExGraph.Vertex do
  @moduledoc false
  use GenServer, restart: :temporary

  import ExGraph.Utils

  # API
  @doc """
    Function called when loading vertex from disk, instead of creating a new one
  """
  def new_vertex(%{index: index, labels: labels, keys: keys}) do
    new_vertex(index, labels, keys, [], true)
  end

  def new_vertex(index, labels \\ [], keys \\ %{}, edges \\ [], revived \\ false) do
    name = index_to_name(index)

    {:ok, _ref} =
      DynamicSupervisor.start_child(
        ExGraph.VertexSupervisor,
        {__MODULE__,
         index: index,
         labels: labels,
         keys: keys,
         edges: edges,
         revived: revived,
         opts: [name: name]}
      )
  end

  def start_link(
        index: index,
        labels: labels,
        keys: keys,
        edges: edges,
        revived: revived,
        opts: opts
      ) do
    GenServer.start_link(__MODULE__, {index, labels, keys, edges, revived}, opts)
  end

  def add_edge(vertex_index, edge_index) do
    add_edges(vertex_index, [edge_index])
  end

  def add_edges(vertex_index, edges_list) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:add_edges, edges_list})
  end

  def remove_edge(vertex_index, edge_index) do
    remove_edges(vertex_index, [edge_index])
  end

  def remove_edges(vertex_index, edges_list) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:remove_edges, edges_list})
  end

  def edges(vertex_index) do
    name = index_to_name(vertex_index)
    GenServer.call(name, :edges)
  end

  def add_label(vertex_index, label) do
    add_labels(vertex_index, [label])
  end

  def add_labels(vertex_index, labels) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:add_labels, labels})
  end

  def remove_label(vertex_index, label) do
    remove_labels(vertex_index, [label])
  end

  def remove_labels(vertex_index, labels) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:remove_labels, labels})
  end

  def labels(vertex_index) do
    name = index_to_name(vertex_index)
    GenServer.call(name, :labels)
  end

  def add_key(vertex_index, key, value) do
    add_keys(vertex_index, %{key => value})
  end

  def add_keys(vertex_index, keys_map) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:add_keys, keys_map})
  end

  def remove_key(vertex_index, key) do
    remove_keys(vertex_index, [key])
  end

  def remove_keys(vertex_index, keys_list) do
    name = index_to_name(vertex_index)
    GenServer.cast(name, {:remove_keys, keys_list})
  end

  def keys(vertex_index) do
    name = index_to_name(vertex_index)
    GenServer.call(name, :keys)
  end

  # Callbacks
  @impl true
  def init({index, labels, keys, edges, revived}) do
    attrs = %{:index => index, :labels => labels, :keys => keys}
    state = {attrs, edges}
    ExGraph.Indexer.add_index(:vertex_index, index, nil)
    Enum.each(labels, fn l -> ExGraph.Indexer.add_index(:label, l, index) end)
    Enum.each(edges, fn e -> Process.monitor(index_to_name(e)) end)

    if !revived do
      persist_to_disk(state)
    end

    {:ok, state}
  end

  @impl true
  def handle_call(:edges, _from, state = {_state, edges}) do
    {:reply, edges, state}
  end

  @impl true
  def handle_call(:labels, _from, state = {%{labels: labels}, _edges}) do
    {:reply, labels, state}
  end

  @impl true
  def handle_call(:keys, _from, state = {%{keys: keys}, _edges}) do
    {:reply, keys, state}
  end

  @impl true
  def handle_cast({:add_edges, edges_list}, {attrs, edges}) do
    Enum.each(edges_list, fn e -> Process.monitor(index_to_name(e)) end)
    edges = edges_list ++ edges
    state = {attrs, edges}
    persist_to_disk(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove_edges, edges_list}, {attrs, edges}) do
    Enum.each(edges_list, fn e -> Process.demonitor(index_to_name(e)) end)
    edges = edges -- edges_list
    state = {attrs, edges}
    persist_to_disk(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_labels, labels_list}, {attrs = %{index: index, labels: labels}, edges}) do
    labels = labels_list ++ labels
    Enum.each(labels_list, fn l -> ExGraph.Indexer.add_index(:label, l, index) end)
    attrs = %{attrs | labels: labels}
    state = {attrs, edges}
    persist_to_disk(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove_labels, labels_list}, {attrs = %{index: index, labels: labels}, edges}) do
    labels = labels -- labels_list
    Enum.each(labels_list, fn l -> ExGraph.Indexer.remove_index(:label, l, index) end)
    attrs = %{attrs | labels: labels}
    state = {attrs, edges}
    persist_to_disk(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:add_keys, keys_map}, {attrs = %{keys: keys}, edges}) do
    keys = Map.merge(keys, keys_map)
    attrs = %{attrs | keys: keys}
    state = {attrs, edges}
    persist_to_disk(state)
    {:noreply, state}
  end

  @impl true
  def handle_cast({:remove_keys, keys_list}, {attrs = %{keys: keys}, edges}) do
    keys = Map.drop(keys, keys_list)
    attrs = %{attrs | keys: keys}
    state = {attrs, edges}
    persist_to_disk(state)
    {:noreply, state}
  end

  @impl true
  def handle_info({:DOWN, _ref, :process, pid, _reason}, {attrs, edges}) do
    name = elem(pid, 0)
    IO.puts("#{inspect(name)}")
    edges = List.delete(edges, name_to_index(name))
    state = {attrs, edges}
    persist_to_disk(state)
    {:noreply, state}
  end

  @impl true
  def handle_info(_msg, state) do
    {:noreply, state}
  end

  # Utils
  defp persist_to_disk({attrs = %{index: index}, edges}) do
    ExGraph.Disk.update_vertex(index_to_name(index), attrs)
    ExGraph.Disk.update_edges(index_to_name(index), edges)
  end
end
