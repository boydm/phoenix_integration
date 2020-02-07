defmodule PhoenixIntegration.Form.TreeEdit do
  @moduledoc """
  Once a tree of `Tag` structures has been created, the values contained
  within it can be overridden by leaves of a different tree provided by
  a test.
  """
  alias PhoenixIntegration.Form.{Change, Tag}

  def apply_change!(tree, %Change{} = tag) do
    {:ok, new_tree} = apply_change(tree, tag)
    new_tree
  end
  
  def apply_change(tree, %Change{} = tag) do
    try do
      {:ok, apply_change(tree, tag.path, tag)}
    catch
      error_code ->
        {:error, error_code}
    end
  end

  defp apply_change(tree, [last], %Change{} = change) do
    case Map.get(tree, last) do
      nil ->
        1 # Map.put_new(tree, last, change)
      %Change{} ->
        2 # Map.update!(tree, last, &(combine_values &1, change))
      %Tag{} = tag ->
        Map.put(tree, last, combine(tag, change))
      _ ->
        3 # throw :lost_value
    end
  end

  defp apply_change(tree, [next | rest], %Change{} = change) do
    case Map.get(tree, next) do
      %Change{} -> # we've reached a leaf but new Change has path left
        4 # throw :lost_value
      %Tag{} -> # we've reached a leaf but new Change has path left
        4.5 # throw :lost_value
      nil ->
        5 # Map.put(tree, next, apply_change(%{}, rest, tag))
      _ -> 
        Map.update!(tree, next, &(apply_change &1, rest, change))
    end
  end
  

  def combine(%Tag{} = tag, %Change{} = change) do
    %Tag{ tag | values: [change.value]}
  end
end
