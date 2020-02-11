defmodule PhoenixIntegration.Form.TreeFinish do
  @moduledoc """
  Once a tree of `Tag` structures has been created and perhaps edited, 
  it is converted to a simple tree as delivered to a controller action.
  """
  alias PhoenixIntegration.Form.Tag

  def to_action_params(tree) when is_map(tree) do
    Enum.reduce(tree, %{}, &to_action_params/2)
  end

  defp to_action_params({key, %Tag{} = tag}, acc) do 
    case {tag.has_list_value, tag.values} do
      {true, values} -> 
        Map.put(acc, key, values)
      {false, [value]} ->
        Map.put(acc, key, value)
      {false, []} ->
        acc
    end
  end

  defp to_action_params({key, submap}, acc) when is_map(submap) do
    Map.put(acc, key, to_action_params(submap))
  end

end  
