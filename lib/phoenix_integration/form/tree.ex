defmodule PhoenixIntegration.Form.Tree do
  alias PhoenixIntegration.Form.Tag

  def add_tag!(tree, %Tag{} = tag) do
    {:ok, new_tree} = add_tag(tree, tag)
    new_tree
  end

  
  def add_tag(tree, %Tag{} = tag) do
    try do
      {:ok, add_tag(tree, tag.path, tag)}
    catch
      error_code ->
        {:error, error_code}
    end
  end

  defp add_tag(tree, [last], %Tag{} = tag) do
    case Map.get(tree, last) do
      nil ->
        Map.put_new(tree, last, tag)
      %Tag{} ->
        Map.update!(tree, last, &(combine_values &1, tag))
      _ ->
        throw :lost_value
    end
  end

  defp add_tag(tree, [next | rest], %Tag{} = tag) do
    case Map.get(tree, next) do
      %Tag{} -> # we've reached a leaf but new Tag has path left
        throw :lost_value
      nil ->
        Map.put(tree, next, add_tag(%{}, rest, tag))
      _ -> 
        Map.update!(tree, next, &(add_tag &1, rest, tag))
    end
  end

  defp combine_values(earlier_tag, later_tag) do
    case {earlier_tag.type, later_tag.type, earlier_tag.has_array_value} do
      {"hidden", "checkbox", _} ->
        implement_hidden_hack(earlier_tag, later_tag)
      {_, _, false} ->
        later_tag
      {_, _, true} ->
        %{earlier_tag | values: earlier_tag.values ++ later_tag.values}
    end
  end

  defp implement_hidden_hack(hidden_tag, checkbox_tag) do
    case checkbox_tag.values == [] do
      true -> hidden_tag
      false -> checkbox_tag
    end
  end
end  
