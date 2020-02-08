defmodule PhoenixIntegration.Form.Change do
  @moduledoc """
  The test asks that a form value be changed. This struct contains 
  the information required to make the change.
  """

  defstruct path: [], value: nil


  def to(path, new_value) when is_list(path) do
    %__MODULE__{path: path, value: new_value}
  end

  def changes(tree), do: changes(tree, [])

  def changes(tree, path_prefix) when is_map(tree) do
    Enum.flat_map(tree, fn {key, value} ->
      changes(value, [key | path_prefix])
    end)
  end

  def changes(value, path_prefix) do
    [to(Enum.reverse(path_prefix), value)]
  end
end
