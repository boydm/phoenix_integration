defmodule PhoenixIntegration.Details.MetaValueTest do
  use ExUnit.Case, async: true
  alias PhoenixIntegration.Form.MetaValue



  describe "merging values that do not collide" do
  end

  describe "colliding values and their special cases" do
    test "by default, the second replaces the first" do
      # first = """
      #   <input type="hidden" name="top_level[param]" value="y">
      # """ |> to_input_value

      # second = """
      #   <input type="text" name="top_level[param]" value="x">
      # """ |> to_input_value

      # assert build_map([first, second]) == %{top_level: %{param: second}}
    end

    test "if the name is an array, new values add on" do
      # first = """
      #   <input type="text" name="top_level[names][]" value="x">
      # """ |> to_input_value

      # second = """
      #   <input type="text" name="top_level[names][]" value="y">
      # """ |> to_input_value

      # %{top_level: %{names: actual}} = build_map([first, second])

      # assert %{values: ["x", "y"], metadata: %{name: "top_level[names]"}} = actual
    end

    test "the same behavior holds for checkbox arrays" do
      # first =  """
      #   <input type="checkbox" name="top_level[grades][]" checked="x" value="first">
      # """ |> to_input_value

      # second = """
      #   <input type="checkbox" name="top_level[grades][]" value="does not appear">
      # """ |> to_input_value

      # third = """
      #   <input type="checkbox" name="top_level[grades][]" checked="anything">
      # """ |> to_input_value

      # %{top_level: %{grades: actual}} = build_map([first, second, third])

      # assert %{values: ["first", "on"]} = actual
    end

    test "checkbox hack: checkbox unchecked" do
      # hidden =  """
      #   <input type="hidden" name="top_level[grade]" value="hidden">
      # """ |> to_input_value

      # ignored = """
      #   <input type="checkbox" name="top_level[grade]" value="ignored">
      # """ |> to_input_value

      # %{top_level: %{grade: actual}} = build_map([hidden, ignored])

      # assert %{values: ["hidden"]} = actual
      # # It shouldn't matter, but it's probably cleanest to keep the
      # # rest of the `hidden` metadata.
      # assert actual.metadata == hidden.metadata
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

  
end
