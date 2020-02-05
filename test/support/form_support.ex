defmodule PhoenixIntegration.FormSupport do
  alias PhoenixIntegration.Form.Tag

  def input_to_tag(fragment),
    do: Floki.parse_fragment!(fragment) |> Tag.new!("input")
end
