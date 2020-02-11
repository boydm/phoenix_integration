defmodule PhoenixIntegration.Form.Util do
  alias PhoenixIntegration.Form.Tag
  
  def symbolize(anything), do: to_string(anything) |> String.to_atom


  def any_leaf(%Tag{} = tag), do: tag
  def any_leaf(tree) do
    {_key, subtree} = Enum.at(tree, 0)
    any_leaf(subtree)
  end

  
end
