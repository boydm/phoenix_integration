defmodule PhoenixIntegration.Form.TreeFinish do
  @moduledoc false
  # Once a tree of `Tag` structures has been created and perhaps edited, 
  # nit is converted to a simple tree as delivered to a controller action.

  alias PhoenixIntegration.Form.Tag

  def to_action_params(tree) when is_map(tree) do
    ignore_tag_like_HTTP_does = &(&1)
    to_params_reducer(tree, ignore_tag_like_HTTP_does)
  end

  defp to_params_reducer(tree, empty_list_handler) when is_map(tree) do
    Enum.reduce(tree, %{}, &(to_params_step &1, &2, empty_list_handler))
    |> Enum.reject(fn {_key, val} -> val == %{} end)
    |> Map.new
  end

  defp to_params_step({key, %Tag{} = tag}, acc, empty_list_handler) do
    case {tag.has_list_value, tag.values} do
      {_, []} ->
        empty_list_handler.(acc)
      {true, values} -> 
        Map.put(acc, key, values)
      {false, [value]} ->
        Map.put(acc, key, value)
      _ ->
        throw "A user error that should have already been reported."
    end
  end

  defp to_params_step({key, submap}, acc, empty_list_handler) when is_map(submap) do
    Map.put(acc, key, to_params_reducer(submap, empty_list_handler))
  end

end  
