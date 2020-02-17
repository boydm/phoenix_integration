defmodule PhoenixIntegration.Details.TreeCreationTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.TreeCreation

  ## Note: error cases are tested elsewhere (currently `messages_test.exs`)

  # ----------------------------------------------------------------------------
  describe "adding tags that have no collisions (and type=text)" do
    test "into an empty tree" do
      tag = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      assert TreeCreation.add_tag!(%{}, tag) == %{top_level: %{param: tag}}
    end

    test "add tag at the same level as a previous tag" do
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

    test "add tag at a deeper level" do
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

    test "adding a tag that represents a list" do
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

    test "a missing type is of type input" do
      # Because the defaulting of the missing type is done at a top
      # level, we can't use the simpler test-support functions.
      snippet = """
        <input name="top_level[param]" value="x">
      """
      form = form_for(snippet)
      created = TreeCreation.build_tree(form)
      assert %{top_level: %{param: tag}} = created.tree
      assert tag.type == "text"
    end
  end

  # ----------------------------------------------------------------------------
  describe "simpler cases where a new tag collides with one already in the tree" do
    # Note: warnings are tested elsewhere
    test "with single values, the second replaces the first" do
      first = """
        <input type="hidden" name="top_level[param]" value="y">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      assert test_tree!([first, second]) == %{top_level: %{param: second}}
    end

    test "if the name is a list, new values add on" do
      first = """
        <input type="text" name="top_level[names][]" value="x">
      """ |> input_to_tag

      second = """
        <input type="text" name="top_level[names][]" value="y">
      """ |> input_to_tag

      %{top_level: %{names: actual}} = test_tree!([first, second])

      assert actual.values == ["x", "y"]
    end

    test "the same behavior adding-on behavior holds for checked checkboxes" do
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

  # ----------------------------------------------------------------------------
  describe "the checkbox hack: a `type=hidden` provides the unchecked value" do 
    test "unchecked checkbox has no effect" do
      hidden =  """
        <input type="hidden" name="top_level[grade]" value="hidden value">
      """ |> input_to_tag

      ignored = """
        <input type="checkbox" name="top_level[grade]" value="ignored">
      """ |> input_to_tag

      %{top_level: %{grade: actual}} = test_tree!([hidden, ignored])

      # It shouldn't matter, but it's probably nicest to keep the
      # hidden tag, rather than replacing it with the "checkbox",
      # since the hidden tag is the one that provides the (default)
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

  # ----------------------------------------------------------------------------
  describe "radio buttons" do
    setup do
      checked = """
         <input type="radio" name="top_level[contact]" value="email" checked>
        """ |> input_to_tag
      unchecked = """
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

    test "no checked button results in no value",
      %{unchecked: unchecked} do

      %{top_level: %{contact: actual}} = test_tree!(unchecked)
      assert_field(actual, values: [])
    end
  end
end
