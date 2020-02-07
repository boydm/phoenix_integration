defmodule PhoenixIntegration.Details.UserValueTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.UserValue

  describe "" do
    test "from" do
      tag = """
        <some_tag_name name="top_level[animal]" value="x">
      """
      |> input_to_tag

      UserValue.from(tag, except: [values: "not x"])
      |> assert_fields(values: "not x",
                       has_array_value: tag.has_array_value,
                       path: tag.path)
    end
  end
end
