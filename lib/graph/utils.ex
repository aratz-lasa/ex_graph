defmodule ExGraph.Utils do
  @moduledoc false

  def index_to_name(index) do
    String.to_atom("ExGraph.Vertex.#{index}")
  end

  def name_to_index(name) do
    to_string(name)
    |> String.split(".")
    |> List.last()
    |> String.to_integer()
  end
end
