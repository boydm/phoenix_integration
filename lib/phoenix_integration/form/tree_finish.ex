defmodule PhoenixIntegration.Form.TreeFinish do
  @moduledoc false
  # Once a tree of `Tag` structures has been created and perhaps edited, 
  # nit is converted to a simple tree as delivered to a controller action.

  alias PhoenixIntegration.Form.Tag

  def to_action_params(tree) when is_map(tree) do
    Enum.reduce(tree, %{}, &to_params/2)
    |> Enum.reject(fn {_key, val} -> val == %{} end)
    |> Map.new
  end

  def to_params(tree) when is_map(tree) do
    Enum.reduce(tree, %{}, &to_params/2)
    |> Enum.reject(fn {_key, val} -> val == %{} end)
    |> Map.new
  end

  defp to_params({key, %Tag{} = tag}, acc) do 
    case {tag.has_list_value, tag.values} do
      {_, []} ->
        acc
      {true, values} -> 
        Map.put(acc, key, values)
      {false, [value]} ->
        Map.put(acc, key, value)
      _ ->
        throw "A user error that should have already been reported."
    end
  end

  defp to_params({key, submap}, acc) when is_map(submap) do
    Map.put(acc, key, to_params(submap))
  end

end  
