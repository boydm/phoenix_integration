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
          {tree_so_far, errors_so_far ++ [error]}
      end
    end

    case Enum.reduce(changes, {tree, []}, reducer) do
      {new_tree, []} -> 
        {:ok, new_tree}
      {_, errors} ->
        {:error, errors}
    end
  end

  def apply_change!(tree, %Change{} = change) do
    {:ok, new_tree} = apply_change(tree, change)
    new_tree
  end
  
  def apply_change(tree, %Change{} = change) do
    try do
      {:ok, apply_change(tree, change.path, change)}
    catch
      {description, context} ->
        additional_context = Map.put(context, :change, change)
        {:error, {description, additional_context}}
    end
  end

  defp apply_change(tree, [last], %Change{} = change) do
    case Map.get(tree, last) do
      %Tag{} = tag ->
        Map.put(tree, last, combine(tag, change))
      _ ->
        throw no_such_name_in_form(tree, last)
    end
  end

  defp apply_change(tree, [next | rest], %Change{} = change) do
    case Map.has_key?(tree, next) do
      true -> 
        Map.update!(tree, next, &(apply_change &1, rest, change))
      false ->
        throw no_such_name_in_form(tree, next)
    end
  end

  defp no_such_name_in_form(tree, key) do
    {:no_such_name_in_form,
     %{tree: tree, last_tried: key}
    }
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
