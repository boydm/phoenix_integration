defmodule PhoenixIntegration.Form.Messages do
  @moduledoc """
  The various messages - both warnings and errors - that can be given to the user. 
  """

  @messages %{
    no_such_name_in_form: "Attempted to set missing input in form",
    tag_has_no_name: "A tag has no name",
  }

  def emit(message_tuples, form) do
    Enum.map(message_tuples, fn {message_atom, data} ->
      emit(message_atom, form, data)
    end)
  end


  def emit(message_atom, form, data) when is_list(data) do
    apply(__MODULE__, message_atom, [form | data])
  end

  def emit(message_atom, form, data) do
    emit(message_atom, form, [data])
  end

  def no_such_name_in_form(form, change) do
    error(
      form_description(form, :no_such_name_in_form) <>
      key_values([
        "Setting key", inspect(change.path),
        "And value", inspect(change.value),
      ]))
  end

  def tag_has_no_name(form, floki_tag) do
    warning(get(:tag_has_no_name))
  end

  defp form_description(form, message_key) do
    [action] = Floki.attribute(form, "action")
    
    "#{IO.ANSI.red()}#{get(message_key)}\n" <>
      key_value("Form action", inspect action) <>
      case Floki.attribute(form, "id") do
        [] -> ""
        [id] -> key_value("Form id", inspect id)
      end
  end

  defp key_values(list) do
    list
    |> Enum.chunk_every(2)
    |> Enum.map(fn [key, value] -> key_value(key, value) end)
    |> Enum.join
  end
  
  defp key_value(key, value) do
    "#{IO.ANSI.green()}#{key}: #{IO.ANSI.red()}#{value}\n"
  end
  
  defp error(msg), do: IO.puts "Error: #{msg}"

  defp warning(msg), do: IO.puts "Warning: #{msg}"

  # This is used for testing.
  def get(key), do: @messages[key]
end
