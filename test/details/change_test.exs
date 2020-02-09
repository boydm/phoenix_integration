defmodule PhoenixIntegration.Details.ChangeTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.Change

  test "to" do
    tag = """
      <input name="top_level[animal]" value="x">
    """
    |> input_to_tag

    assert Change.to(tag.path, "not x") == %Change{path: tag.path, value: "not x"}
  end

  describe "changes" do 
    test "typical case" do
      input = %{top_level:
                %{lower: "lower",
                  continue: %{continued: [1, 2, 3]}
                }}

      [continued, lower] = Change.changes(input) |> sort_by_value

      assert_fields(lower,
        path: [:top_level, :lower],
        value: "lower")
      assert_fields(continued,
        path: [:top_level, :continue, :continued],
        value: [1, 2, 3])
    end

    test "empty case" do
      assert [] == Change.changes(%{})
    end

    test "empty leaf case" do 
      input = %{top_level:
                %{lower: "lower",
                  continue: %{}
                }}

      [lower] = Change.changes(input)
      assert_fields(lower,
        path: [:top_level, :lower],
        value: "lower")
    end
  end

  defp sort_by_value(changes),
    do: Enum.sort_by(changes, &(to_string &1.value))
end
