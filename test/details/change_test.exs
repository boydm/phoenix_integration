defmodule PhoenixIntegration.Details.ChangeTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  # import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.Change


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

  defstruct shallow: nil, deep: %{}

  describe "structs produce optional paths" do
    test "a simple case" do
      input = %{top_level:
                %{struct: %__MODULE__{shallow: "shallow"}}}

      [only] = Change.changes(input)

      assert_fields(only,
        path: [:top_level, :struct, :shallow],
        value: "shallow",
        ignore_if_missing_from_form: true)
    end

    test "a nested case" do
      input = %{top_level:
                %{struct: %__MODULE__{
                     shallow: "shallow",
                     deep: %__MODULE__{shallow: "deeper shallow"}},
                  non_struct: "simple"}}

      [deeper, shallow, simple] = Change.changes(input) |> sort_by_value

      assert_fields(deeper,
        path: [:top_level, :struct, :deep, :shallow],
        value: "deeper shallow",
        ignore_if_missing_from_form: true)
      assert_fields(shallow,
        path: [:top_level, :struct, :shallow],
        value: "shallow",
        ignore_if_missing_from_form: true)
      assert_fields(simple,
        path: [:top_level, :non_struct],
        value: "simple",
        ignore_if_missing_from_form: false)
    end

  end

  defp sort_by_value(changes) do
    Enum.sort_by(changes, &(to_string &1.value))
  end
end
