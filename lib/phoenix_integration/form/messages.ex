defmodule PhoenixIntegration.Form.Messages do
  
  @moduledoc """
  The various messages - both warnings and errors - that can be given to the user. 
  """
  alias PhoenixIntegration.Form.Common

  @messages %{
    no_such_name_in_form: "You tried to set the value of a tag that isn't in the form.",
    arity_clash: "You are combining list and scalar values.",
    tag_has_no_name: "A form entry has no name.",
    empty_name: "A tag has an empty name.",
    form_conflicting_paths: "The form has two conflicting names."
  }

  def no_such_name_in_form(self, form, context) do
    hint =
      case context.why do
        :path_too_long -> 
          color(:red, "Your path is longer than the names it should match.\n") <>
            key_values(:red, [
              "Here is your path", inspect(context.change.path),
              "Here is an available name", context.tree[context.last_tried].name])
        :path_too_short -> 
              color(:red, "You provided only a prefix of all the available names.\n") <>
              key_values(:red, [
                "Here is your path", inspect(context.change.path),
                "Here is an available name", Common.any_leaf(context.tree).name])
        :possible_typo -> 
          key_values(:red, [
                "Path tried", inspect(context.change.path),
                "Is this a typo?", "#{inspect context.last_tried}",
                "Your value", inspect(context.change.value)])
      end

    error(
      color(:red, get(self)) <> "\n" <>
      hint <>
      form_description(:red, form))
  end

  def arity_clash(self, form, %{existing: existing, change: change}) do
    hint =
      case existing.has_list_value do
        true ->
          color(:red, "Note that the name of the tag you're setting ends in `[]`:\n") <>
          color(:red, "    " <> inspect existing.name) <>
          color(:red, "\nSo your value should be a list, rather than this:\n") <>
          color(:red, "    " <> inspect change.value)
        false ->
          color(:red, "The value you want to use is a list:\n") <>
          color(:red, "    " <> inspect change.value) <>
          color(:red, "\nBut the name of the tag doesn't end in `[]`:\n") <>
          color(:red, "    " <> inspect existing.name)
      end

    error(
      color(:red, get(self)) <> "\n" <>
      hint <> "\n" <>
      form_description(:red, form))
  end


  def tag_has_no_name(self, form, floki_tag) do
    warning(
      color(:yellow, Map.get(@messages, self)) <> "\n" <>
      color(:yellow, Floki.raw_html(floki_tag)) <> "\n" <>
      color(:yellow, "It can't be included in the params sent to the controller.\n") <>
      form_description(:yellow, form)
    )
  end

  def empty_name(self, form, floki_tag) do
    warning(
      color(:yellow, Map.get(@messages, self)) <> "\n" <>
      color(:yellow, Floki.raw_html(floki_tag)) <> "\n" <>
      form_description(:yellow, form)
    )
  end

  def form_conflicting_paths(self, form, %{old: old, new: new}) do
    warning(
      color(:yellow, Map.get(@messages, self)) <> "\n" <>
      color(:yellow, "Phoenix will ignore one of them.\n") <>
      key_values(:yellow, [
        "Earlier name", old.name,
        "  Later name", new.name,
      ]) <>
      form_description(:yellow, form))
  end


  ### Support

  def emit(message_tuples, form) do
    Enum.map(message_tuples, fn {message_atom, data} ->
      emit(message_atom, form, data)
    end)
  end

  def emit(message_atom, form, data) when is_list(data) do
    apply(__MODULE__, message_atom, [message_atom, form] ++ data)    
  end

  def emit(message_atom, form, data) do
    emit(message_atom, form, [data])
  end

  defp form_description(severity, form) do
    [action] = Floki.attribute(form, "action")
    
    key_value(severity, "Form action", inspect action) <>
      case Floki.attribute(form, "id") do
        [] -> ""
        [id] -> key_value(severity, "Form id", inspect id)
      end
  end

  defp key_values(severity, list) do
    list
    |> Enum.chunk_every(2)
    |> Enum.map(fn [key, value] -> key_value(severity, key, value) end)
    |> Enum.join
  end
  
  defp key_value(severity, key, value) do
    "#{color(:green)}#{key}: #{color(severity)}#{value}\n"
  end
  
  defp error(msg), do: puts(:red, "Error", msg)
  defp warning(msg), do: puts(:yellow, "Warning", msg)
  

  defp puts(severity, tag, msg),
    do: IO.puts "#{color severity}#{tag}: #{msg}#{color :default_color}"
    

  defp color(key), do: apply(IO.ANSI, key, [])

  defp color(key, msg), do: color(key) <> msg
    

  # This is used for testing.
  def get(key), do: @messages[key]
end
