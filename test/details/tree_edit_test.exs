defmodule PhoenixIntegration.Details.TreeEditTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.{TreeEdit, UserValue, Tag}

  test "simple case" do
    first = """
    <input type="text" name="top_level[first]" value="x">
    """ |> input_to_tag
    
    second = """
    <input type="text" name="top_level[param][deeper]" value="y">
    """ |> input_to_tag
    
    third = """
    <input type="text" name="top_level[param][wider]" value="z">
    """ |> input_to_tag
    
    
    original = build_tree!([first, second, third])
    replacement = UserValue.from(first, except: [values: ["zzzz"]])
    
    TreeEdit.override(original, replacement)
    |> require_ok
    |> refute_changed([second, third])
    |> assert_changed(first, values: ["zzzz"])
  end

  defp require_ok({:ok, val}), do: val

  def assert_changed(tree, old_leaf, changes) do
    get_in(tree, old_leaf.path)
    |> assert_copy(old_leaf, except: changes)
  end

  def refute_changed(tree, list) when is_list(list) do
    for elt <- list, do: refute_changed(tree, elt)
    tree
  end
  
  def refute_changed(tree, %Tag{} = original_tag) do
    tree
  end
end
