defmodule PhoenixIntegration.Form.MetaValue do
  import PhoenixIntegration.Form.Tag

  defstruct values: nil, metadata: %{}

  def basic(floki_tag) do
    [given_name] = Floki.attribute(floki_tag, "name")
    {name, has_array_value} =
      if String.ends_with?(given_name, "[]") do 
        {String.trim_trailing(given_name, "[]"), true}
      else
        {given_name, false}
      end

    %__MODULE__{metadata: %{name: name,
                            has_array_value: has_array_value}}
  end

  def new(floki_tag, "input") do
    [type] = Floki.attribute(floki_tag, "type")
    basic(floki_tag)
    |> put_values(calculate_value(floki_tag, type))
    |> put_metadata(:type, type)
  end

      

  # Special cases as described in
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input/checkbox
  defp calculate_value(floki_tag, "checkbox") do
    case {Floki.attribute(floki_tag, "checked"),
          Floki.attribute(floki_tag, "value")} do
      {[_],[]} -> ["on"]
      {[_],value} -> value
      {[],_} -> []
    end
  end
  defp calculate_value(floki_tag, _), do: Floki.attribute(floki_tag, "value")

  def enter_value(tree, %__MODULE__{} = meta_value) do
    {:ok, path} = path_to(meta_value)
    enter_value(tree, path, meta_value)
  end

  def enter_value(tree, [last], %__MODULE__{} = meta_value) do
    case Map.get(tree, last) do
      nil ->
        Map.put_new(tree, last, meta_value)
      %__MODULE__{} ->
        Map.update!(tree, last, &(combine_values &1, meta_value))
      _ ->
        raise(
           """
           The name `#{meta_value.metadata.name}` doesn't make sense.
           If you search the HTML source, you'll see there are other
           tags with longer names, something like `#{meta_value.metadata.name}[something]`.
           """)
    end
  end

  def enter_value(tree, [next | rest], %__MODULE__{} = meta_value) do
    case Map.get(tree, next) do
      %__MODULE__{} = _cannot_descend_further_down_existing_tree ->
        raise(
           """
           The name `#{meta_value.metadata.name}` doesn't make sense
           given that there's already a tag whose name is a prefix of that."
           """)
      nil ->
        Map.put(tree, next, enter_value(%{}, rest, meta_value))
      _ -> 
        Map.update!(tree, next, &(enter_value &1, rest, meta_value))
    end
  end

  def combine_values(earlier, later) do
    earlier_type = earlier.metadata.type
    later_type = later.metadata.type
    both_have_array_value = later.metadata.has_array_value
    case {earlier_type, later_type, both_have_array_value} do
      {"hidden", "checkbox", _} ->
        IO.inspect earlier
        later
      {_, _, false} ->
        later
      {_, _, true} -> 
        put_values(earlier, earlier.values ++ later.values)
    end
  end

  defp symbolize(anything), do: to_string(anything) |> String.to_atom

  defp put_values(struct, values),
    do: %{struct | values: values}
  
  defp put_metadata(struct, key, value),
    do: %{struct | metadata: Map.put(struct.metadata, key, value)}



  ### Copied from Requests.ex
  def path_to(%__MODULE__{} = value) do
    case Regex.scan(~r/\w+/, value.metadata.name) do
      [] ->
        {:error, :unknown_format}

      keys ->
        {:ok, Enum.map(keys, &(List.first(&1) |> symbolize))}
    end
  end

  # def nested_value([[key] | keys], value) do
  #   %{String.to_atom(key) => nested_value(keys, value)}
  # end

  # def nested_value([], value) do
  #   value
  # end


  
end
