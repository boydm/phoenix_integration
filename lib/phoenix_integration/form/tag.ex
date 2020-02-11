defmodule PhoenixIntegration.Form.Tag do
  alias PhoenixIntegration.Form.Util

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
  #   - some tags are associated with an list of values. Those tags
  #     will have named ending in `[]`: `name="animal[nicknames][]`.
  #   - others have one value, or occasionally zero values (such as an
  #     unchecked checkbox).
  defstruct has_list_value: false,
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

  def new!(floki_tag) do
    {:ok, %__MODULE__{} = tag} = new(floki_tag)
    tag
  end

  def new(floki_tag) do
    with(
      [name] <- Floki.attribute(floki_tag, "name"),
      :ok <- check_phoenix_conventions(name)
    ) do
      {:ok, safe_new(floki_tag, name)}
    else
      [] ->
        {:warning, :tag_has_no_name, floki_tag}
      :empty_name ->
        {:warning, :empty_name, floki_tag}
    end
  end

  defp safe_new(floki_tag, name) do
    type =
      case Floki.attribute(floki_tag, "type") do
        [] -> nil
        [x] -> x
      end

    checked = Floki.attribute(floki_tag, "checked") != []
    
    %__MODULE__{tag: tag_name(floki_tag),
                original: floki_tag,
                type: type,
                name: name,
                checked: checked
    }
    |> add_fields_that_depend_on_name
    |> add_values
  end

  defp add_fields_that_depend_on_name(so_far) do
    has_list_value = String.ends_with?(so_far.name, "[]")
    path =
      case has_list_value do
        false -> path_to(so_far.name)
        true -> path_to(String.trim_trailing(so_far.name, "[]"))
      end

    %{ so_far |
       path: path,
       has_list_value: has_list_value}
  end

  defp add_values(%{tag: "textarea"} = so_far) do
    raw_value = Floki.FlatText.get(so_far.original)
    %{so_far | values: [raw_value]}
  end    
    
  defp add_values(%{tag: "select"} = so_far) do
    case Floki.find(so_far.original, "option[selected]") do
      [] ->
        %{so_far | values: []}
      selected_option -> 
        case Floki.attribute(selected_option, "value") do
          [] ->
            # "if no value attribute is included, the value defaults to the
            # text contained inside the element" -
            # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select
            %{so_far | values: [Floki.FlatText.get(selected_option)]}
          values  -> 
            %{so_far | values: values}
        end
    end
  end    
    
  defp add_values(%{tag: "input"} = so_far) do
    raw_values = Floki.attribute(so_far.original, "value")
    %{so_far | values: apply_input_special_cases(so_far, raw_values)}
  end

  # Special cases as described in
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input/checkbox
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/radio  
  defp apply_input_special_cases(%{type: "checkbox"} = so_far, raw_values),
    do: tags_with_checked_attribute(so_far, raw_values)

  defp apply_input_special_cases(%{type: "radio"} = so_far, raw_values),
    do: tags_with_checked_attribute(so_far, raw_values)

  defp apply_input_special_cases(_so_far, raw_values), do: raw_values

  defp tags_with_checked_attribute(so_far, raw_values) do
    case {so_far.checked, raw_values} do 
      {true,[]} -> ["on"]
      {true,values} -> values
      {false,_} -> []
    end
  end

  defp path_to(name) do
    name
    |> separate_name_pieces
    |> Enum.map(&(List.first(&1) |> Util.symbolize))
  end
    
  defp check_phoenix_conventions(name) do
    case separate_name_pieces(name) do
      [] ->
        :empty_name
      _ ->
        :ok
    end
  end

  defp separate_name_pieces(name), do: Regex.scan(~r/\w+/, name)

  # Floki allows tags to come in two forms
  defp tag_name([floki_tag]), do: tag_name(floki_tag)
  defp tag_name({name, _, _}), do: name
end
