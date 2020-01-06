defmodule Graph.Indexer do
  @moduledoc false
  use GenServer

  # API
  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: Graph.Indexer)
  end

  def add_index(index_type, index, index_value) do
    GenServer.cast(Graph.Indexer, {:add_index, {index_type, index, index_value}})
  end

  def remove_index(index_type, index, index_value) do
    GenServer.cast(Graph.Indexer, {:remove_index, {index_type, index, index_value}})
  end

  def get_index(index_type, index) do
    GenServer.call(Graph.Indexer, {:get_index, {index_type, index}})
  end

  def get_indexes(index_type) do
    GenServer.call(Graph.Indexer, {:get_indexes, index_type})
  end

  # Callbacks
  @impl true
  def init(:ok) do
    {:ok, %{:vertex_index => %{}, :label => %{}}}
  end

  @impl true
  def handle_cast({:add_index, {index_type, index, index_value}}, state) do
    state =
      if Map.has_key?(state, index_type) do
        state
      else
        Map.put(state, index_type, %{})
      end

    %{^index_type => indexes} = state

    indexes =
      if Map.has_key?(indexes, index) do
        indexes
      else
        Map.put(indexes, index, [])
      end

    %{^index => index_list} = indexes
    indexes = Map.put(indexes, index, [index_value | index_list])
    {:noreply, %{state | index_type => indexes}}
  end

  @impl true
  def handle_cast({:remove_index, {index_type, index, index_value}}, state) do
    %{^index_type => indexes} = state
    %{^index => index_list} = indexes
    indexes = Map.put(indexes, index, List.delete(index_list, index_value))
    {:noreply, %{state | index_type => indexes}}
  end

  @impl true
  def handle_call({:get_index, {index_type, index}}, _from, state) do
    %{^index_type => indexes} = state
    %{^index => index_value} = indexes
    {:reply, index_value, state}
  end

  @impl true
  def handle_call({:get_indexes, index_type}, _from, state) do
    %{^index_type => indexes} = state
    {:reply, indexes, state}
  end
end
