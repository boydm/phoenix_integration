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
      case apply_change(acc.tree, change) do
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

  def apply_change!(tree, %Change{} = change) do
    {:ok, new_tree} = apply_change(tree, change)
    new_tree
  end
  
  def apply_change(tree, %Change{} = change) do
    try do
      {:ok, apply_change(tree, change.path, change)}
    catch
      {description, context} ->
        handle_oddity(description, context, tree, change)
    end
  end

  def handle_oddity(:no_such_name_in_form, %{why: :possible_typo}, tree,
    %{ignore_if_missing_from_form: true}),
    do: {:ok, tree}

  def handle_oddity(description, context, _tree, _change),
    do: {:error, description, context}

  defp apply_change(tree, [last], %Change{} = change) do
    case Map.get(tree, last) do
      %Tag{} = tag ->
        Map.put(tree, last, combine(tag, change))
      nil ->
        throw no_such_name_in_form(:possible_typo, tree, last, change)
      _ ->
        throw no_such_name_in_form(:path_too_short, tree, last, change)
    end
  end

  defp apply_change(tree, [next | rest], %Change{} = change) do
    case Map.get(tree, next) do
      %Tag{} -> 
        throw no_such_name_in_form(:path_too_long, tree, next, change)
      nil -> 
        throw no_such_name_in_form(:possible_typo, tree, next, change)
      _ ->
        Map.update!(tree, next, &(apply_change &1, rest, change))
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
