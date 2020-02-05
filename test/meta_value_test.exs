defmodule PhoenixIntegration.MetaValueTest do
  use ExUnit.Case, async: true
  alias PhoenixIntegration.MetaValue


  describe "name data" do
    test "an ordinary nested value" do
      actual = """
        <arbitrary name="top_level[param]" value="">
      """
      |> parse_fragment!
      |> MetaValue.basic

      assert actual.metadata == %{
        name: "top_level[param]",
        has_array_value: false,
      }
    end

    test "an array-type value" do
      actual = """
        <arbitrary name="top_level[param][]" value="x">
      """
      |> parse_fragment!
      |> MetaValue.basic

      assert actual.metadata == %{
        name: "top_level[param]",
        has_array_value: true
      }
    end
  end

  describe "input tags" do
    test "extra keys that are set" do 
      actual = """
        <input type="text" name="top_level[param]" value="x">
      """
      |> to_input_value

      assert actual.values == ["x"]
      assert actual.metadata == %{
        name: "top_level[param]",
        has_array_value: false,
        type: "text"
      }
    end

    test "a missing value defaults to the empty string" do 
      actual = """
        <input type="text" name="top_level[param]" value="x">
      """
      |> to_input_value

      assert actual.values == ["x"]
      assert actual.metadata == %{
        name: "top_level[param]",
        has_array_value: false,
        type: "text"
      }
    end
  end

  describe "input tags when a value must be checked to take effect" do
    # Special cases for checkboxes as described in
    # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input/checkbox
    test "a checkbox that's omitted `checked`" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" value="x">
      """, []
    end

    test "a checkbox that has any value for `checked`" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" checked="true" value="x">
      """, ["x"]
    end

    test "a checkbox that is checked but has no explicit value" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" checked="true">
      """, ["on"]
    end

    test "a checkbox that's part of an array has the same effect" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" value="x">
      """, []

      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" checked="true" value="x">
      """, ["x"]

      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" checked="anything">
      """, ["on"]
    end
  end


  describe "merging values that do not collide" do
    test "into an empty form" do
      fragment = """
        <input type="text" name="top_level[param]" value="x">
      """ |> to_input_value

      actual = MetaValue.enter_value(%{}, fragment)
      assert actual == %{top_level: %{param: fragment}}
    end

    test "value at the same level" do
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> to_input_value

      second = """
        <input type="text" name="top_level[other_param]" value="y">
      """ |> to_input_value

      
      actual = build_map([first, second])
      expected = %{top_level:
                   %{param: first,
                     other_param: second}}
      assert actual == expected
    end

    test "values at different levels" do
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> to_input_value

      second = """
        <input type="text" name="top_level[other_param][deeper]" value="y">
      """ |> to_input_value

      third = """
        <input type="text" name="top_level[other_param][wider]" value="z">
      """ |> to_input_value

      
      actual = build_map([first, second, third])
      expected = %{top_level:
                   %{param: first,
                     other_param: %{deeper: second,
                                    wider: third}}}
      assert actual == expected
    end

    test "merging an array value" do
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> to_input_value

      second = """
        <input type="text" name="top_level[other_param][]" value="y">
      """ |> to_input_value
      
      actual = build_map([first, second])
      expected = %{top_level:
                   %{param: first,
                     other_param: second}}
      assert actual == expected
    end

    test "a path can't have both a value and a nested value" do
      # Phoenix does accept this, possibly by accident.
      # The original value is lost.
      first = """
        <input type="text" name="top_level[param]" value="x">
      """ |> to_input_value

      second = """
        <input type="text" name="top_level[param][subparam]" value="y">
      """ |> to_input_value

      
      actual = MetaValue.enter_value(%{}, first)

      assert_raise(RuntimeError, fn -> 
        MetaValue.enter_value(actual, second)
      end)
    end

    test "a path can't introduce a name when there's already a more deeply nested one" do
      # Phoenix retains the earlier (more nested) value.
      first = """
        <input type="text" name="top_level[param][subparam]" value="y">
      """ |> to_input_value

      second = """
        <input type="text" name="top_level[param]" value="x">
      """ |> to_input_value

      
      actual = MetaValue.enter_value(%{}, first)

      assert_raise(RuntimeError, fn -> 
        MetaValue.enter_value(actual, second)
      end)
    end
  end

  describe "colliding values and their special cases" do
    test "by default, the second replaces the first" do
      first = """
        <input type="hidden" name="top_level[param]" value="y">
      """ |> to_input_value

      second = """
        <input type="text" name="top_level[param]" value="x">
      """ |> to_input_value

      assert build_map([first, second]) == %{top_level: %{param: second}}
    end

    test "if the name is an array, new values add on" do
      first = """
        <input type="text" name="top_level[names][]" value="x">
      """ |> to_input_value

      second = """
        <input type="text" name="top_level[names][]" value="y">
      """ |> to_input_value

      %{top_level: %{names: actual}} = build_map([first, second])

      assert %{values: ["x", "y"], metadata: %{name: "top_level[names]"}} = actual
    end

    test "the same behavior holds for checkbox arrays" do
      first =  """
        <input type="checkbox" name="top_level[grades][]" checked="x" value="first">
      """ |> to_input_value

      second = """
        <input type="checkbox" name="top_level[grades][]" value="does not appear">
      """ |> to_input_value

      third = """
        <input type="checkbox" name="top_level[grades][]" checked="anything">
      """ |> to_input_value

      %{top_level: %{grades: actual}} = build_map([first, second, third])

      assert %{values: ["first", "on"]} = actual
    end

    test "checkbox hack: checkbox unchecked" do
      hidden =  """
        <input type="hidden" name="top_level[grade]" value="hidden">
      """ |> to_input_value

      ignored = """
        <input type="checkbox" name="top_level[grade]" value="ignored">
      """ |> to_input_value

      %{top_level: %{grade: actual}} = build_map([hidden, ignored])

      assert %{values: ["hidden"]} = actual
      # It shouldn't matter, but it's probably cleanest to keep the
      # rest of the `hidden` metadata.
      assert actual.metadata == hidden.metadata
    end
  end    

  defp parse_fragment!(fragment) do 
    {:ok, result} = Floki.parse_fragment(fragment)
    result
  end

  defp to_input_value(fragment),
    do: parse_fragment!(fragment) |> MetaValue.new("input")

  defp assert_input_values(fragment, values) do
    assert to_input_value(fragment).values == values
  end

  
  defp build_map(meta_values) when is_list(meta_values) do
    Enum.reduce(meta_values, %{}, fn meta_value, acc ->
      MetaValue.enter_value(acc, meta_value)
    end)
  end
end
