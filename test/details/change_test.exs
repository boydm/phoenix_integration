defmodule PhoenixIntegration.Details.ChangeTest do
  use ExUnit.Case, async: true
  # import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.Change

  test "creation" do
    tag = """
      <some_tag_name name="top_level[animal]" value="x">
    """
    |> input_to_tag

    assert Change.to(tag.path, "not x") == %Change{path: tag.path, value: "not x"}
  end
end
