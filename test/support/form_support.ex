defmodule PhoenixIntegration.FormSupport do
  alias PhoenixIntegration.Form.{Tag,Tree}

  def input_to_tag(fragment),
    do: Floki.parse_fragment!(fragment) |> Tag.new!("input")

  def build_tree!(tags) when is_list(tags) do
    Enum.reduce(tags, %{}, fn tag, acc ->
      Tree.add_tag!(acc, tag)
    end)
  end

  def build_tree(tags) when is_list(tags) do
    Enum.reduce_while(tags, %{}, fn tag, acc ->
      case Tree.add_tag(acc, tag) do
        {:ok, new_tree} -> {:cont, new_tree}
        err -> {:halt, err}
      end
    end)
  end
  
end
