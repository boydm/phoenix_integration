defmodule PhoenixIntegration.Form.Tag do

  @moduledoc """
  This is a representation of a value-providing tag in a Phoenix-style
  HTML form. It converts Floki tag structures into a more convenient form,
  and transforms data.

  It is used to construct trees like the params delivered to
  a Phoenix controller, except that all the keys are symbols rather
  than strings (for the user's convenience).

  In an intermediate step, each leaf is a `Form.Tag` which is later converted
  into a normal (string) HTTP value.
  """

  # There are two types of tags.
  #   - some tags are associated with an array of values. Those tags
  #     will have named ending in `[]`: `name="animal[nicknames][]`.
  #   - others have one value, or occasionally zero values (such as an
  #     unchecked checkbox).
  defstruct has_array_value: false,
    # To accommodate the different tags, values are always stored in a
    # list. The empty list represents a tag without a value.
    values: [],
    # The name is as given in the HTML tag.
    name: nil,
    # The path is the name split up into a list of symbols representing
    # the tree structure implied by the[bracketed[name]].
    path: [],
    # The name of the tag, like `"input"`
    tag: "",
    # Where relevant, the value of the "type=" attribute of the tag, or nil.
    type: nil,
    # Whether the particular value is checked (checkboxes, someday multi-selects).
    checked: false,
    # The original Floki tag, for convenience.
    original: nil
  
  IO.puts "Should the tree as delivered to the controller be turned into strings?"
  # Note the case where a form uses integer ids as keys (as in a list of
  # checkboxes from which a user will select a set of animals).

  def new!(floki_tag, tag_name) do
    {:ok, %__MODULE__{} = tag} = new(floki_tag, tag_name)
    tag
  end

  def new(floki_tag, tag_name) do
    [name] = Floki.attribute(floki_tag, "name")

    case check_phoenix_conventions(name) do
      :ok -> {:ok, safe_new(floki_tag, tag_name, name)}
      otherwise -> otherwise
    end
  end

  defp safe_new(floki_tag, tag_name, name) do
    type =
      case Floki.attribute(floki_tag, "type") do
        [] -> nil
        [x] -> x
      end

    checked = Floki.attribute(floki_tag, "checked") != []
    
    %__MODULE__{tag: tag_name,
                original: floki_tag,
                type: type,
                name: name,
                checked: checked
    }
    |> add_fields_that_depend_on_name
    |> add_values
  end

  defp add_fields_that_depend_on_name(so_far) do
    has_array_value = String.ends_with?(so_far.name, "[]")
    path =
      case has_array_value do
        false -> path_to(so_far.name)
        true -> path_to(String.trim_trailing(so_far.name, "[]"))
      end

    %{ so_far |
       path: path,
       has_array_value: has_array_value}
  end

  defp add_values(so_far) do
    raw_values = Floki.attribute(so_far.original, "value")
    %{so_far | values: calculate_values(so_far, raw_values)}
  end

  # Special cases as described in
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input/checkbox
  defp calculate_values(%{type: "checkbox"} = so_far, raw_values) do
    case {so_far.checked, raw_values} do 
      {true,[]} -> ["on"]
      {true,values} -> values
      {false,_} -> []
    end
  end
  defp calculate_values(_so_far, raw_values), do: raw_values

  defp path_to(name) do
    name
    |> separate_name_pieces
    |> Enum.map(&(List.first(&1) |> symbolize))
  end
    
  defp check_phoenix_conventions(name) do
    case separate_name_pieces(name) do
      [] ->
        {:error, :unknown_format}
      _ ->
        :ok
    end
  end

  defp separate_name_pieces(name), do: Regex.scan(~r/\w+/, name)

  defp symbolize(anything), do: to_string(anything) |> String.to_atom
  
end
