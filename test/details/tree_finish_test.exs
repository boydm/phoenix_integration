defmodule PhoenixIntegration.Details.TreeFinishTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.{TreeFinish, Change, Tag}

  describe "converting the values into a map sent to an action" do
    test "a scalar" do
      actual = 
        """
          <input type="text" name="top_level[first]" value="first value">
        """
        |> input_to_tag
        |> build_tree!
        |> TreeFinish.to_action_params

      assert actual == %{top_level: %{first: "first value"}}
    end
  end

  test "an array" do
    actual = [
        """
          <input type="text" name="top_level[list][]" value="list 1"">
        """ |> input_to_tag,
        """
          <input type="text" name="top_level[list][]" value="list 2"">
        """ |> input_to_tag
    ]
    |> build_tree!
    |> TreeFinish.to_action_params

    
    assert %{top_level: %{list: list}} = actual
    assert Enum.sort(list) == ["list 1", "list 2"]
  end

  test "an unchecked checkbox (and no `hidden`)" do
    actual = [
        """
          <input type="checkbox" name="top_level[checked]" value="unused">
        """ |> input_to_tag,
        # So there's something to see
        """
          <input type="text" name="top_level[first]" value="first value">
        """ |> input_to_tag,
    ]
    |> build_tree!
    |> TreeFinish.to_action_params

    assert %{top_level: %{first: "first value"}} == actual
  end
  
end
