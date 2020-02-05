defmodule PhoenixIntegration.Details.TreeTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.{Tag,Tree}

  describe "adding tags that have no collisions" do
    test "into an empty tree" do
      tag = """
        <input type="text" name="top_level[param]" value="x">
      """ |> input_to_tag

      assert Tree.add_tag!(%{}, tag) == %{top_level: %{param: tag}}
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

    test "a path can't introduce a name when there's already a more deeply nested one"
    #   # Phoenix retains the earlier (more nested) value.
    #   first = """
    #     <input type="text" name="top_level[param][subparam]" value="y">
    #   """ |> input_to_tag

    #   second = """
    #     <input type="text" name="top_level[param]" value="x">
    #   """ |> input_to_tag

      
    #   actual = MetaValue.enter_value(%{}, first)

    #   assert_raise(RuntimeError, fn -> 
    #     MetaValue.enter_value(actual, second)
    #   end)

    
    test "an array that collides with a plain value"
  end

  defp build_tree!(tags) when is_list(tags) do
    Enum.reduce(tags, %{}, fn tag, acc ->
      Tree.add_tag!(acc, tag)
    end)
  end

  defp build_tree(tags) when is_list(tags) do
    Enum.reduce_while(tags, %{}, fn tag, acc ->
      case Tree.add_tag(acc, tag) do
        {:ok, new_tree} -> {:cont, new_tree}
        err -> {:halt, err}
      end
    end)
  end
end
