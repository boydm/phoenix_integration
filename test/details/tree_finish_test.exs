defmodule PhoenixIntegration.Details.TreeFinishTest do
  use ExUnit.Case, async: true
  # import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.{TreeFinish}

  describe "converting the values into a map sent to an action" do
    test "a scalar" do
      actual = 
        """
          <input type="text" name="top_level[first]" value="first value">
        """
        |> input_to_tag
        |> test_tree!
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
    |> test_tree!
    |> TreeFinish.to_action_params

    
    assert %{top_level: %{list: list}} = actual
    assert Enum.sort(list) == ["list 1", "list 2"]
  end

  test "an empty array means nothing is sent" do
    actual = [
      ~s| <input name="animals[chosen][]" type="checkbox"> |,
      ~s| <input name="animals[chosen][]" type="checkbox"> |,
      # So there's something to see
      ~s| <input name="animals[name]" type="text" /> |]
    |> test_tree!
    |> TreeFinish.to_action_params

    assert %{animals: %{name: ""}} == actual
  end

  test "pruning of the tree when a branch has no values" do
    actual = [
      ~s| <input name="animals[name]" type="text" value="Bossie"/> |,
      """
          <select id="animals_roles" multiple="" name="animals[stats][roles][]">
            <option value="1">Admin</option>
            <option value="2">Power User</option>
          </select>
      """]
    |> test_tree!
    |> TreeFinish.to_action_params

    assert %{animals: %{name: "Bossie"}} == actual
    # Because there's no value for any of the names "under [animals][stats],
    # that entire leaf of the tree is not sent.
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
    |> test_tree!
    |> TreeFinish.to_action_params

    assert %{top_level: %{first: "first value"}} == actual
  end

  test "radio buttons need not have anything checked" do
    # and so send no value.

    actual = [
      ~s| <input type="radio" name="animals[species]" value="bovine" /> |, 
      ~s| <input type="radio" name="animals[species]" value="caprine" /> | ]
    |> test_tree!
    |> TreeFinish.to_action_params

    # Since there's nothing else in the form, nothing is actually sent.
    assert %{} == actual
  end    
end
