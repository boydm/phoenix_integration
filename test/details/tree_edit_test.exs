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

  @original_tree test_tree!([
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

  # ----------------------------------------------------------------------------
  describe "successful updates" do
    test "update a scalar" do 
      change = change(@shallow.path, "different value")
      
      TreeEdit.apply_change(@original_tree, change)
      |> require_ok
      |> refute_changed([@deeper, @list])
      |> assert_changed(@shallow, values: ["different value"])
    end
    
    test "update a deeper scalar, just for fun" do 
      change = change(@deeper.path, "different value")
      
      TreeEdit.apply_change(@original_tree, change)
      |> require_ok
      |> assert_changed(@deeper, values: ["different value"])
    end

    test "update a list-valued tag" do 
      change = change(@list.path, ["different", "values"])
      
      TreeEdit.apply_change(@original_tree, change)
      |> require_ok
      |> assert_changed(@list, values: ["different", "values"])
    end
  end

  # ----------------------------------------------------------------------------
  describe "the types of values accepted as keys" do
    # Note that the resulting tree always has symbol keys, even if the
    # original is a string or integer.
    setup do 
      numeric = """
          <input type="text" name="top_level[lower][0]" value="original">
        """ |> input_to_tag |> test_tree!

      [numeric: numeric]
    end

    test "keys can be symbols", %{numeric: numeric} do
      %{top_level: %{lower: %{"0": actual}}} = 
        TreeEdit.apply_edits(numeric, %{top_level: %{lower: %{"0": "new"}}})
        |> require_ok

      assert actual.values == ["new"]
    end

    test "keys can be strings", %{numeric: numeric} do
      %{top_level: %{lower: %{"0": actual}}} = 
        TreeEdit.apply_edits(numeric, %{top_level: %{lower: %{"0" => "new"}}})
        |> require_ok

      assert actual.values == ["new"]
    end

    test "keys can be integers", %{numeric: numeric} do
      %{top_level: %{lower: %{"0": actual}}} = 
        TreeEdit.apply_edits(numeric, %{top_level: %{lower: %{0 => "new"}}})
        |> require_ok

      assert actual.values == ["new"]
    end
  end

  # ----------------------------------------------------------------------------
  test "a bit more complicated example: more than one edited value" do
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

  # ----------------------------------------------------------------------------
  defstruct day: nil, hour: nil

  describe "handling of structures" do
    test "a value can be set from structure keys" do
      day =
        """
        <input type="text" name="top_level[day]" value="">
        """ |> input_to_tag

      hour = 
        """
        <input type="text" name="top_level[hour]" value="">
        """ |> input_to_tag
      tree = test_tree!([day, hour])

      TreeEdit.apply_edits(tree, %{top_level: %__MODULE__{day: "Fri", hour: "12"}})
      |> require_ok
      |> assert_changed(day, values: ["Fri"])
      |> assert_changed(hour, values: ["12"])
    end

    test "unused keys are ignored" do
      day =
        """
        <input type="text" name="top_level[day]">
        """ |> input_to_tag
      tree = test_tree!([day])

      TreeEdit.apply_edits(tree, %{top_level: %__MODULE__{day: "Fri", hour: "12"}})
      |> require_ok
      |> assert_changed(day, values: ["Fri"])
    end
  end
  # ----------------------------------------------------------------------------
  describe "handling of files" do
    setup do 
      tag =
        """
        <input type="file" name="top_level[picture]">
        """ |> input_to_tag
      [tree: test_tree!([tag])]
    end

    test "one normally sets a Plug.Upload", %{tree: tree} do
      upload = %Plug.Upload{content_type: "image/jpg",
                            path: "/var/mytests/photo.jpg",
                            filename: "photo.jpg"}

      {:ok, edited} = TreeEdit.apply_edits(tree, %{top_level: %{picture: upload}})
      assert edited.top_level.picture.values == [upload]
    end
    
    test "In case they're not using Plug.Upload, a string is accepted",
      %{tree: tree} do

      {:ok, edited} = TreeEdit.apply_edits(tree, %{top_level: %{picture: "filename"}})
      assert edited.top_level.picture.values == ["filename"]
    end
  end

  # ----------------------------------------------------------------------------

  
  defp require_ok({:ok, val}), do: val

  defp assert_changed(new_tree, old_leaf, changes) do
    get_in(new_tree, old_leaf.path)
    |> assert_copy(old_leaf, except: changes)
    new_tree
  end

  defp refute_changed(new_tree, list) when is_list(list) do
    for old_leaf <- list, do: refute_changed(new_tree, old_leaf)
    new_tree
  end
  
  defp refute_changed(new_tree, %Tag{} = old_leaf) do
    assert get_in(new_tree, old_leaf.path) == old_leaf
  end

  defp change(path, value), do: %Change{path: path, value: value}
end
