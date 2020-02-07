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
      %Tag{} = tag ->
        Map.put(tree, last, combine(tag, change))
    end
  end

  defp apply_change(tree, [next | rest], %Change{} = change) do
    case Map.get(tree, next) do
      _ -> 
        Map.update!(tree, next, &(apply_change &1, rest, change))
    end
  end
  

  def combine(%Tag{} = tag, %Change{} = change) do
    case {is_list(change.value), tag.has_list_value} do
      {true, true} -> 
        %Tag{ tag | values: change.value}
      {false, false} ->
        %Tag{ tag | values: [change.value]}
    end
  end
end
