defmodule PhoenixIntegration.Details.TreeTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  alias PhoenixIntegration.Form.{Tag,Tree}

  describe "adding tags that have no collisions" do
    test "into an empty form" do
      # fragment = """
      # <input type="text" name="top_level[param]" value="x">
      # """ |> to_input_value
      
      # actual = MetaValue.enter_value(%{}, fragment)
      # assert actual == %{top_level: %{param: fragment}}
    end
  end
end
