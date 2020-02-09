defmodule PhoenixIntegration.Form.TreeEdit do
  @moduledoc """
  Once a tree of `Tag` structures has been created, the values contained
  within it can be overridden by leaves of a different tree provided by
  a test.
  """
  alias PhoenixIntegration.Form.{Change, Tag}

  def apply_edits(tree, edit_tree) do
    changes = Change.changes(edit_tree)
    
    reducer = fn change, {tree_so_far, errors_so_far} ->
      case apply_change(tree_so_far, change) do
        {:ok, new_tree} ->
          {new_tree, errors_so_far}
        {:error, error} ->
          {tree_so_far, [error | errors_so_far]}
      end
    end

    case Enum.reduce(changes, {tree, []}, reducer) do
      {new_tree, []} -> 
        {:ok, new_tree}
      {_, errors} ->
        {:error, errors}
    end
  end

  def apply_change!(tree, %Change{} = tag) do
    {:ok, new_tree} = apply_change(tree, tag)
    new_tree
  end
  
  def apply_change(tree, %Change{} = tag) do
    try do
      {:ok, apply_change(tree, tag.path, tag)}
    catch
      description ->
        {:error, {description, tag}}
    end
  end

  defp apply_change(tree, [last], %Change{} = change) do
    case Map.get(tree, last) do
      %Tag{} = tag ->
        Map.put(tree, last, combine(tag, change))
      _ ->
        throw :no_such_name_in_form
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
