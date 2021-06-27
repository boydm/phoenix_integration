defmodule PhoenixIntegration.Form.Messages do
  @moduledoc false
  # The various messages - both warnings and errors - that can be given to the user.
  alias PhoenixIntegration.Form.Common

  @headlines %{
    no_such_name_in_form: "You tried to set the value of a tag that isn't in the form.",
    arity_clash: "You are combining list and scalar values.",
    tag_has_no_name: "A form tag has no name.",
    empty_name: "A tag has an empty name.",
    form_conflicting_paths: "The form has two conflicting names."
  }

  # This is used for testing as well as within this module.
  def get(key), do: @headlines[key]

  # ----------------------------------------------------------------------------
  # Entry point

  def emit(message_tuples, form) do
    Enum.map(message_tuples, fn {message_atom, data} ->
      emit_one(message_atom, form, data)
    end)
  end

  defp emit_one(message_atom, form, context) when is_list(context) do
    {severity, iodata} =
      apply(__MODULE__, message_atom, [get(message_atom), form] ++ context)
    warnings? = Application.get_env(:phoenix_integration, :warnings, true)

    case {severity, warnings?} do
      {:error, _} ->
        put_iodata(:red, "Error", iodata)
      {:warning, true}  ->
        put_iodata(:yellow, "Warning", iodata)
      {:warning, false} ->
        :ignore
    end
  end

  defp emit_one(message_atom, form, context) do
    emit_one(message_atom, form, [context])
  end

  # ----------------------------------------------------------------------------
  # A function for each headline

  def no_such_name_in_form(headline, form, context) do
    hint =
      case context.why do
        :path_too_long -> [
          "Your path is longer than the names it should match.",
          key_values([
           "Here is your path", inspect(context.change.path),
           "Here is an available name", context.tree[context.last_tried].name])
        ]
        :path_too_short -> [
          "You provided only a prefix of all the available names.",
          key_values([
            "Here is your path", inspect(context.change.path),
            "Here is an available name", Common.any_leaf(context.tree).name])
        ]
        :possible_typo ->
          key_values([
           "Path tried", inspect(context.change.path),
           "Is this a typo?", "#{inspect context.last_tried}",
           "Your value", inspect(context.change.value)])
      end

    {:error, [headline, hint, form_description(form)]}
  end

  def arity_clash(headline, form, %{existing: existing, change: change}) do
    hint =
      case existing.has_list_value do
        true -> [
          "Note that the name of the tag you're setting ends in `[]`:",
          "    #{inspect existing.name}",
          "So your value should be a list, rather than this:",
          "    #{inspect change.value}",
        ]
        false -> [
          "The value you want to use is a list:",
          "    #{inspect change.value}",
          "But the name of the tag doesn't end in `[]`:",
          "    #{inspect existing.name}"
        ]
      end

    {:error, [headline, hint, form_description(form)]}
  end

  def tag_has_no_name(headline, form, floki_tag) do
    {:warning, [
        headline,
        Floki.raw_html(floki_tag),
        "It can't be included in the params sent to the controller.",
        form_description(form),
      ]}
  end

  def empty_name(headline, form, floki_tag) do
    {:warning, [
        headline,
        Floki.raw_html(floki_tag),
        form_description(form),
      ]}
  end

  def form_conflicting_paths(headline, form, %{old: old, new: new}) do
    {:warning, [
        headline,
        "Phoenix will ignore one of them.",
        key_values([
              "Earlier name", old.name,
              "  Later name", new.name,
            ]),
        form_description(form),
    ]}
  end

  # ----------------------------------------------------------------------------
  # This prints (to stdio) an iodata tree, but unlike IO.puts, it adds
  # a newline at the end of each element. It also handles color.

  defp put_iodata(color, word, [headline | rest]) do
    prefix = apply(IO.ANSI, color, [])

    IO.puts "#{prefix}#{word}: #{headline}"
    for iodata <- rest, do: put_iodata(iodata)
    IO.puts "#{IO.ANSI.reset}"
  end

  defp put_iodata(iodata) when is_list(iodata) do
    for line <- iodata, do: put_iodata(line)
  end

  defp put_iodata(string) when is_binary(string), do: IO.puts string

  # ----------------------------------------------------------------------------

  defp form_description(form) do
    [action] = Floki.attribute(form, "action")

    [ key_value("Form action", inspect action),
      case Floki.attribute(form, "id") do
        [] -> []
        [id] -> key_value("Form id", inspect id)
      end
    ]
  end

  defp key_values(list) do
    list
    |> Enum.chunk_every(2)
    |> Enum.map(fn [key, value] -> key_value(key, value) end)
  end

  defp key_value(key, value) do
    "#{key}: #{value}"
  end
end
