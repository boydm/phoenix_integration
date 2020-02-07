defmodule PhoenixIntegration.Form.TreeEdit do
  alias PhoenixIntegration.Form.{UserValue, Tag}

  def override!(tree, %UserValue{} = tag) do
    {:ok, new_tree} = override(tree, tag)
    new_tree
  end
  
  def override(tree, %UserValue{} = tag) do
    try do
      {:ok, override(tree, tag.path, tag)}
    catch
      error_code ->
        {:error, error_code}
    end
  end

  defp override(tree, [last], %UserValue{} = user_value) do
    case Map.get(tree, last) do
      nil ->
        1 # Map.put_new(tree, last, user_value)
      %UserValue{} ->
        2 # Map.update!(tree, last, &(combine_values &1, user_value))
      %Tag{} = tag ->
        Map.put(tree, last, combine(tag, user_value))
      _ ->
        3 # throw :lost_value
    end
  end

  defp override(tree, [next | rest], %UserValue{} = user_value) do
    case Map.get(tree, next) do
      %UserValue{} -> # we've reached a leaf but new UserValue has path left
        4 # throw :lost_value
      %Tag{} -> # we've reached a leaf but new UserValue has path left
        4.5 # throw :lost_value
      nil ->
        5 # Map.put(tree, next, override(%{}, rest, tag))
      _ -> 
        Map.update!(tree, next, &(override &1, rest, user_value))
    end
  end
  

  def combine(%Tag{} = tag, %UserValue{} = user_value) do
    %Tag{ tag | values: user_value.values}
  end
end
