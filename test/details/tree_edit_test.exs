defmodule PhoenixIntegration.Details.TreeEditTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.{TreeEdit, Change, Tag}

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
    change = Change.to(first.path, "zzzz")
    
    TreeEdit.apply_change(original, change)
    |> require_ok
    |> refute_changed([second, third])
    |> assert_changed(first, values: ["zzzz"])
  end

  defp require_ok({:ok, val}), do: val

  def assert_changed(new_tree, old_leaf, changes) do
    get_in(new_tree, old_leaf.path)
    |> assert_copy(old_leaf, except: changes)
  end

  def refute_changed(new_tree, list) when is_list(list) do
    for old_leaf <- list, do: refute_changed(new_tree, old_leaf)
    new_tree
  end
  
  def refute_changed(new_tree, %Tag{} = old_leaf) do
    assert get_in(new_tree, old_leaf.path) == old_leaf
  end
end
