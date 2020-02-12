defmodule PhoenixIntegration.Form.TreeEdit do
  @moduledoc """
  Once a tree of `Tag` structures has been created, the values contained
  within it can be overridden by leaves of a different tree provided by
  a test.
  """
  alias PhoenixIntegration.Form.{Change, Tag, Common}

  defstruct valid?: :true, tree: %{}, errors: []

  def apply_edits(tree, edit_tree) do
    changes = Change.changes(edit_tree)
    
    reducer = fn change, acc ->
      case apply_change(change, acc.tree) do
        {:ok, new_tree} ->
          Common.put_tree(acc, new_tree)
        {:error, message_atom, message_context} ->
          Common.put_error(acc, message_atom, message_context)
      end
    end

    case Enum.reduce(changes, %__MODULE__{tree: tree}, reducer) do
      %{valid?: true, tree: tree} -> {:ok, tree}
      %{errors: errors} -> {:error, errors}
    end
  end

  def apply_change!(%Change{} = change, tree) do
    {:ok, new_tree} = apply_change(change, tree)
    new_tree
  end
  
  def apply_change(%Change{} = change, tree) do
    try do
      {:ok, apply_change(change.path, change, tree)}
    catch
      {description, context} ->
        {:error, description, context}
    end
  end

  defp apply_change([last], %Change{} = change, tree) do
    case Map.get(tree, last) do
      %Tag{} = tag ->
        Map.put(tree, last, combine(tag, change))
      nil ->
        throw no_such_name_in_form(:possible_typo, tree, last, change)
      _ ->
        throw no_such_name_in_form(:path_too_short, tree, last, change)
    end
  end

  defp apply_change([next | rest], %Change{} = change, tree) do
    case Map.get(tree, next) do
      %Tag{} -> 
        throw no_such_name_in_form(:path_too_long, tree, next, change)
      nil -> 
        throw no_such_name_in_form(:possible_typo, tree, next, change)
      _ ->
        Map.update!(tree, next, &(apply_change rest, change, &1))
    end
  end

  defp no_such_name_in_form(why, tree, key, change) do
    {:no_such_name_in_form,
     %{why: why, tree: tree, last_tried: key, change: change}
    }
  end

  def combine(%Tag{} = tag, %Change{} = change) do
    case {is_list(change.value), tag.has_list_value} do
      {true, true} -> 
        %Tag{ tag | values: change.value}
      {false, false} ->
        %Tag{ tag | values: [change.value]}
      _ ->
        throw {:arity_clash, %{existing: tag, change: change}}
    end
  end
end
