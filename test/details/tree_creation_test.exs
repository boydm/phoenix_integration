defmodule PhoenixIntegration.Details.TreeCreationTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.TreeCreation

  describe "adding tags that have no collisions" do
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

      
      actual = build_tree!([first, second])
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

      
      actual = build_tree!([first, second, third])
      expected = %{top_level:
                   %{param: first,
                     other_param: %{deeper: second,
                                    wider: third}}}
      assert actual == expected
    end

    test "merging an array value" do
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[other_param][]" value="y">
      """ |> input_to_tag
      
      actual = build_tree!([first, second])
      expected = %{top_level:
                   %{param: first,
                     other_param: second}}
      assert actual == expected
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

      assert build_tree!([first, second]) == %{top_level: %{param: second}}
    end

    test "if the name is an array, new values add on" do
      first = """
        <input type="text" name="top_level[names][]" value="x">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[names][]" value="y">
      """ |> input_to_tag

      %{top_level: %{names: actual}} = build_tree!([first, second])

      assert actual.values == ["x", "y"]
    end

    test "the same behavior holds for checkbox arrays" do
      first =  """
        <input type="checkbox" name="top_level[grades][]" checked="x" value="first">
      """ |> input_to_tag

      second = """
        <input type="checkbox" name="top_level[grades][]" value="does not appear">
      """ |> input_to_tag

      third = """
        <input type="checkbox" name="top_level[grades][]" checked="anything">
      """ |> input_to_tag

      %{top_level: %{grades: actual}} = build_tree!([first, second, third])

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

      %{top_level: %{grade: actual}} = build_tree!([hidden, ignored])

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

      %{top_level: %{grade: actual}} = build_tree!([hidden, checked])

      actual
      |> assert_fields(values: ["replace"],
                       type: "checkbox")
    end
  end
end
