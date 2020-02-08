defmodule PhoenixIntegration.Details.TreeEditTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.{TreeEdit, Change, Tag}

  @shallow """
        <input type="text" name="top_level[first]" value="first value">
      """ |> input_to_tag
      
  @deeper """
        <input type="text" name="top_level[second][deeper]" value="deeper value">
      """ |> input_to_tag

  @original_tree build_tree!([
    @shallow,
    @deeper,
    """
      <input type="text" name="top_level[list][]" value="list 1"">
    """ |> input_to_tag,
    """
      <input type="text" name="top_level[list][]" value="list 2"">
    """ |> input_to_tag
    ])
    
  @list get_in(@original_tree, [:top_level, :list])

  describe "successful updates" do
    test "update a scalar" do 
      change = Change.to(@shallow.path, "different value")
      
      TreeEdit.apply_change(@original_tree, change)
      |> require_ok
      |> refute_changed([@deeper, @list])
      |> assert_changed(@shallow, values: ["different value"])
    end
    
    test "update a deeper one, just for fun" do 
      change = Change.to(@deeper.path, "different value")
      
      TreeEdit.apply_change(@original_tree, change)
      |> require_ok
      |> assert_changed(@deeper, values: ["different value"])
    end

    test "update a list" do 
      change = Change.to(@list.path, ["different", "values"])
      
      TreeEdit.apply_change(@original_tree, change)
      |> require_ok
      |> assert_changed(@list, values: ["different", "values"])
    end
  end

  describe "error cases" do
    @tag :skip
    test "path of change is too short"
    @tag :skip
    test "path of change is too long"
    @tag :skip
    test "updating a scalar with an array"
    @tag :skip
    test "updating a list with a scalar"
  end

  test "applying user edits" do
    edits = %{top_level:
              %{second: %{deeper: "new deeper value"},
                list: ["shorter list"]}
             }

    TreeEdit.apply_edits(@original_tree, edits)
    |> require_ok
    |> assert_changed(@deeper, values: ["new deeper value"])
    |> assert_changed(@list, values: ["shorter list"])
    |> refute_changed(@shallow)
  end
    

  defp require_ok({:ok, val}), do: val

  def assert_changed(new_tree, old_leaf, changes) do
    get_in(new_tree, old_leaf.path)
    |> assert_copy(old_leaf, except: changes)
    new_tree
  end

  def refute_changed(new_tree, list) when is_list(list) do
    for old_leaf <- list, do: refute_changed(new_tree, old_leaf)
    new_tree
  end
  
  def refute_changed(new_tree, %Tag{} = old_leaf) do
    assert get_in(new_tree, old_leaf.path) == old_leaf
  end
end
