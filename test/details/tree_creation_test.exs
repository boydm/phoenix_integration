defmodule PhoenixIntegration.Details.TreeCreationTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.TreeCreation

  describe "adding tags that have no collisions (and type=text)" do
    test "into an empty tree" do
      tag = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      assert TreeCreation.add_tag!(%{}, tag) == %{top_level: %{param: tag}}
    end

    test "value at the same level" do
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[other_param]" value="y">
      """ |> input_to_tag

      
      actual = test_tree!([first, second])
      expected = %{top_level:
                   %{param: first,
                     other_param: second}}
      assert actual == expected
    end

    test "values at different levels" do
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[other_param][deeper]" value="y">
      """ |> input_to_tag

      third = """
        <input type="text" name="top_level[other_param][wider]" value="z">
      """ |> input_to_tag

      
      actual = test_tree!([first, second, third])
      expected = %{top_level:
                   %{param: first,
                     other_param: %{deeper: second,
                                    wider: third}}}
      assert actual == expected
    end

    test "merging a list value" do
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[other_param][]" value="y">
      """ |> input_to_tag
      
      actual = test_tree!([first, second])
      expected = %{top_level:
                   %{param: first,
                     other_param: second}}
      assert actual == expected
    end


    # Because the correction of the type is done at a top
    # level, we can't use the simpler test-support functions.
    test "a missing type is of type input" do
      snippet = """
        <input name="top_level[param]" value="x">
      """
      form = form_for(snippet)
      assert {:ok, %{top_level: %{param: tag}}} = TreeCreation.build_tree(form)
      assert tag.type == "text"
    end
    
    test "a path can't have both a value and a nested value" do
      # Phoenix does accept this, possibly by accident.
      # The original value is lost. We complain.
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[param][subparam]" value="y">
      """ |> input_to_tag

      
      actual = build_tree([first, second])
      assert actual == {:error, :lost_value}
    end

    test "a path can't introduce a name when there's already a more deeply nested one" do
      # Phoenix retains the earlier (more nested) value.
      first = """
        <input type="text" name="top_level[param][subparam]" value="y">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      
      actual = build_tree([first, second])
      assert actual == {:error, :lost_value}
    end
  end

  describe "simpler cases where a new tag collides with one already in the tree" do
    test "with single values, the second replaces the first" do
      first = """
        <input type="hidden" name="top_level[param]" value="y">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      assert test_tree!([first, second]) == %{top_level: %{param: second}}
    end

    test "if the name is an list, new values add on" do
      first = """
        <input type="text" name="top_level[names][]" value="x">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[names][]" value="y">
      """ |> input_to_tag

      %{top_level: %{names: actual}} = test_tree!([first, second])

      assert actual.values == ["x", "y"]
    end

    test "the same behavior holds for checkbox lists" do
      first =  """
        <input type="checkbox" name="top_level[grades][]" checked="x" value="first">
      """ |> input_to_tag

      second = """
        <input type="checkbox" name="top_level[grades][]" value="does not appear">
      """ |> input_to_tag

      third = """
        <input type="checkbox" name="top_level[grades][]" checked="anything">
      """ |> input_to_tag

      %{top_level: %{grades: actual}} = test_tree!([first, second, third])

      assert actual.values == ["first", "on"]
    end
  end

  describe "the checkbox hack: a `type=hidden` provides the unchecked value" do 
    test "unchecked checkbox has no effect" do
      hidden =  """
        <input type="hidden" name="top_level[grade]" value="hidden value">
      """ |> input_to_tag

      ignored = """
        <input type="checkbox" name="top_level[grade]" value="ignored">
      """ |> input_to_tag

      %{top_level: %{grade: actual}} = test_tree!([hidden, ignored])

      # It shouldn't matter, but it's probably nicest to keep 
      # the hidden tag, since it's the one that provides the (default)
      # value for the current form.
      actual
      |> assert_fields(values: ["hidden value"],
                       type: "hidden")
    end


    test "checked checkbox replaces the hidden value" do
      hidden =  """
        <input type="hidden" name="top_level[grade]" value="hidden">
      """ |> input_to_tag

      checked = """
        <input type="checkbox" name="top_level[grade]" checked="true" value="replace">
      """ |> input_to_tag

      %{top_level: %{grade: actual}} = test_tree!([hidden, checked])

      actual
      |> assert_fields(values: ["replace"],
                       type: "checkbox")
    end
  end

  describe "radio buttons" do
    setup do
      checked =
        """
         <input type="radio" name="top_level[contact]" value="email" checked>
        """ |> input_to_tag
      unchecked =
        """
         <input type="radio" name="top_level[contact]" value="phone">
        """ |> input_to_tag

      [checked: checked, unchecked: unchecked]
    end
    

    test "checked radio replaces the unchecked value",
      %{checked: checked, unchecked: unchecked} do

      %{top_level: %{contact: actual}} = test_tree!([unchecked, checked])
      assert_field(actual, values: ["email"])
    end

    test "unchecked radio does not replace the checked value",
      %{checked: checked, unchecked: unchecked} do

      %{top_level: %{contact: actual}} = test_tree!([checked, unchecked])
      assert_field(actual, values: ["email"])
    end

    test "it's fine for there to be no checked button",
      %{unchecked: unchecked} do

      %{top_level: %{contact: actual}} = test_tree!(unchecked)
      assert_field(actual, values: [])
    end

  end

end
