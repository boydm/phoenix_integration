defmodule PhoenixIntegration.Form.Tag do
  alias PhoenixIntegration.Form.Common

  @moduledoc false
  # A `Tag` is a representation of a value-providing HTML tag within a
  # Phoenix-style HTML form. Tags live on the leaves of a tree (nested
  # `Map`) representing the whole form. See [DESIGN.md](./DESIGN.md) for
  # more.

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
    # The tag itself, like `"input"` or "textarea".
    tag: "",
    # Where relevant, the value of the "type=" attribute of the tag.
    # Otherwise should be unused.
    type: nil,
    # Whether the particular value is checked (checkboxes, selects).
    checked: false,
    # The original Floki tag.
    original: nil
  
  def new!(floki_tag) do
    {:ok, %__MODULE__{} = tag} = new(floki_tag)
    tag
  end

  def new(floki_tag) do
    with(
      [name] <- Floki.attribute(floki_tag, "name"),
      :ok <- check_name(name)
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
        [] -> "`type` irrelevant for `#{name}`"
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

  # ----------------------------------------------------------------------------
  defp add_fields_that_depend_on_name(incomplete_tag) do
    has_list_value = String.ends_with?(incomplete_tag.name, "[]")
    path =
      case has_list_value do
        false -> path_to(incomplete_tag.name)
        true -> path_to(String.trim_trailing(incomplete_tag.name, "[]"))
      end

    %{ incomplete_tag |
       path: path,
       has_list_value: has_list_value}
  end

  # ----------------------------------------------------------------------------
  defp add_values(%{tag: "textarea"} = incomplete_tag) do
    raw_value = Floki.FlatText.get(incomplete_tag.original)
    %{incomplete_tag | values: [raw_value]}
  end    
    
  defp add_values(%{tag: "select"} = incomplete_tag) do
    selected_values = fn selected_options ->
      case Floki.attribute(selected_options, "value") do
        [] ->
          # "if no value attribute is included, the value defaults to the
          # text contained inside the element" -
          # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select
          [Floki.FlatText.get(selected_options)]
        values -> 
          values
      end
    end

    value_when_no_option_is_selected = fn select ->
      multiple? = Floki.attribute(select, "multiple") != []
      options = Floki.find(select, "option")
      case {multiple?, options} do
        # I don't see it explicitly stated, but the value of a
        # non-multiple `select` with no selected option is the value
        # of the first option.
        {false, [first|_rest]} -> selected_values.(first)
        {true, _}              -> []
        # A `select` with no options is pretty silly. Nevertheless.        
        {_, []}                -> []
      end
    end

    values = 
      case Floki.find(incomplete_tag.original, "option[selected]") do
        [] ->
          value_when_no_option_is_selected.(incomplete_tag.original)
        selected_options ->
          selected_values.(selected_options)
      end
    %{incomplete_tag | values: values}
  end
    
  defp add_values(%{tag: "input"} = incomplete_tag) do
    raw_values = Floki.attribute(incomplete_tag.original, "value")
    %{incomplete_tag | values: apply_input_special_cases(incomplete_tag, raw_values)}
  end

  # ----------------------------------------------------------------------------
  # Special cases for `input` tags as described in
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input/checkbox
  # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/radio  
  defp apply_input_special_cases(%{type: "checkbox"} = incomplete_tag, values),
    do: tags_with_checked_attribute(incomplete_tag, values)

  defp apply_input_special_cases(%{type: "radio"} = incomplete_tag, values),
    do: tags_with_checked_attribute(incomplete_tag, values)

  # This catches the zillion variants of the type="text" tag.
  defp apply_input_special_cases(_incomplete_tag, []), do: [""]

  defp apply_input_special_cases(_incomplete_tag, values), do: values

  # ----------------------------------------------------------------------------
  defp tags_with_checked_attribute(incomplete_tag, values) do
    case {incomplete_tag.checked, values} do 
      {true,[]} -> ["on"]
      {true,values} -> values
      {false,_} -> []
    end
  end

  # ----------------------------------------------------------------------------
  defp path_to(name) do
    name
    |> separate_name_pieces
    |> Enum.map(&(List.first(&1) |> Common.symbolize))
  end
    
  defp check_name(name) do
    case separate_name_pieces(name) do
      [] ->
        :empty_name
      _ ->
        :ok
    end
  end

  defp separate_name_pieces(name), do: Regex.scan(~r/[^\[\]]+/, name)

  # Floki allows tags to come in two forms
  defp tag_name([floki_tag]), do: tag_name(floki_tag)
  defp tag_name({name, _, _}), do: name
end
