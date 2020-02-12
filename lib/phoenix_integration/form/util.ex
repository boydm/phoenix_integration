defmodule PhoenixIntegration.Form.Util do
  alias PhoenixIntegration.Form.Tag
  
  def symbolize(anything), do: to_string(anything) |> String.to_atom


  @doc "In trees whose leaves are tags, find some arbitrary leaf."
  def any_leaf(%Tag{} = tag), do: tag
  def any_leaf(tree) do
    {_key, subtree} = Enum.at(tree, 0)
    any_leaf(subtree)
  end

  # Tree creation and editing follow the same basic code structure and
  # use struct definitions with a common "shape". These utilities work
  # with that. (Low-rent behaviours.) 
  
  def put_tree(acc, tree), do: %{acc | tree: tree}

  def put_warning(acc, message_atom, message_context),
    do: put_message(acc, :warnings, message_atom, message_context)

  def put_error(acc, message_atom, message_context) do
    acc
    |> put_message(:errors, message_atom, message_context)
    |> Map.put(:valid?, false)
  end
  
  defp put_message(acc, kind, message_atom, message_context),
    do: Map.update!(acc, kind, &(&1 ++ [{message_atom, message_context}]))
end
