defmodule PhoenixIntegration.Form.Messages do
  @moduledoc """
  The various messages - both warnings and errors - that can be given to the user. 
  """

  def emit(message_atom, form, data) when is_list(data),
    do: apply(__MODULE__, message_atom, [form | data])

  def emit(message_atom, form, data),
    do: emit(message_atom, form, [data])

  def no_such_name_in_form(form, change) do
    error(
      form_description(form, "Attempted to set missing input in form") <>
      key_values([
        "Setting key", inspect(change.path),
        "And value", inspect(change.value),
      ]))
  end

  defp form_description(form, msg) do
    [action] = Floki.attribute(form, "action")
    
    "#{IO.ANSI.red()}#{msg}\n" <>
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
  
  defp error(msg), do: IO.puts msg
end
