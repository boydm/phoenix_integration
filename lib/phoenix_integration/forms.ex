defmodule PhoenixIntegration.Forms do
#  import IEx


  #----------------------------------------------------------------------------
  def find( html, identifier, method \\ nil, form_finder \\ "form" ) do
    # scan all links, return the first where either the path or the content
    # is equal to the identifier
    Floki.find(html, form_finder)
    |> Enum.find_value( fn(form) ->
      {"form", _attribs, _kids} = form
 
      case identifier do
        "#" <> id ->
          case Floki.attribute(form, "id") do
            [^id] -> form
            _ -> nil
          end
        "/" <> _ ->
          case Floki.attribute(form, "action") do
            [^identifier] -> form
            _ -> nil
          end
        "http" <> _ ->
          case Floki.attribute(form, "action") do
            [^identifier] -> form
            _ -> nil
          end
        _ ->
          cond do
            # see if the identifier is in the links's text
            Floki.text(form) =~ identifier -> form
            # all other cases fail
            true -> nil
          end
      end
      |> verify_form_method(method)
    end)
    |> case do
      nil ->
        {err_type, err_ident} = case identifier do
          "#" <> id ->    {"id=", id}
          "/" <> _ ->     {"action=", identifier}
          "http" <> _ ->  {"action=", identifier}
          _ ->            {"text containing ", identifier}
        end
        msg = "Failed to find form \"#{identifier}\", :#{method} in the response\n" <>
          "Expected to find a form with #{err_type}\"#{err_ident}\""
        raise msg
      form ->
        [path] = Floki.attribute(form, "action")
        {:ok, path, form_method(form), form}
    end
  end

  #----------------------------------------------------------------------------
  def build_form_data(form, fields) do
    form_data = build_form_by_type(form, %{}, "input")
    form_data = build_form_by_type(form, form_data, "textarea")
    form_data = build_form_by_type(form, form_data, "select")

    # merge the data from the form and that provided by the test
    merge_grouped_fields( form_data, fields )
  end

  #========================================================
  # support for find

  #--------------------------------------------------------
  defp verify_form_method(false, _method),  do: false
  defp verify_form_method(nil, _method),    do: false
  defp verify_form_method(form, nil), do: form            # return form f no method requested
  defp verify_form_method(form, method) do
    method = to_string(method)
    form_method(form)
    |> case do
      ^method -> form
      _ -> false
    end
  end

  #--------------------------------------------------------
  defp form_method(form) do
        case Floki.find( form, "input[name=\"_method\"]" ) do
      [] ->
        "post"
      [found_input] ->
        [found_method] = Floki.attribute(found_input, "value")
        found_method
    end
  end


  #========================================================
  # support for building form data

  #----------------------------------------------------------------------------
  def build_form_by_type(form, acc, input_type) do
    Enum.reduce(Floki.find(form, input_type), acc, fn(input, acc) ->
      case input_to_key_value(input, input_type) do
        {:ok, key, value} ->
          cond do
            is_map(value) ->
              # merge group named inputs together
              Map.put(acc, key, Map.merge( acc[key] || %{}, value))
            true ->
              Map.put(acc, key, value)
          end
        {:error, _} ->
          acc # do nothing
      end
    end )
  end

  #----------------------------------------------------------------------------'
  defp input_to_key_value(input, input_type) do
    case Floki.attribute(input, "type") do
      ["radio"] ->
        case Floki.attribute(input, "checked") do
          ["checked"] ->
            really_input_to_key_value(input, input_type)
          _ ->
            {:error, "skip"}
        end
      _ -> really_input_to_key_value(input, input_type)
    end
  end
  defp really_input_to_key_value(input, input_type) do
    case Floki.attribute(input, "name") do
      [] ->     {:error, :no_name}
      [name] -> interpret_named_value(name, get_input_value(input, input_type))
      _ ->      {:error, :unknown_format}
    end
  end

  #----------------------------------------------------------------------------
  defp merge_grouped_fields(map, fields) do
    Enum.reduce(fields, map, fn({k,v}, acc) ->
      cond do
        is_map(v) ->
          sub_map = merge_grouped_fields( acc[k] || %{}, v )
          put_if_available!(acc, k, sub_map)
        true ->
          put_if_available!(acc, k, v)
      end
    end)
  end

  #----------------------------------------------------------------------------
  defp put_if_available!(map, key, value) do
    case Map.has_key?(map, key) do
      true ->   Map.put(map, key, value)
      false ->
        msg = "#{IO.ANSI.red}Attempted to set missing input in form\n" <>
          "#{IO.ANSI.green}Setting key: #{IO.ANSI.red}#{key}\n" <>
          "#{IO.ANSI.green}And value: #{IO.ANSI.red}#{value}\n" <>
          "#{IO.ANSI.green}Into fields: #{IO.ANSI.yellow}" <>
          inspect( map )
        raise msg
    end
  end

  #----------------------------------------------------------------------------
  defp get_input_value( input, "input" ),     do: Floki.attribute(input, "value")
  defp get_input_value( input, "textarea" ),  do: [Floki.text(input)]
  defp get_input_value( input, "select" ) do
    Floki.find(input, "option[selected]")
    |> Floki.attribute("value")
  end

  #----------------------------------------------------------------------------'
  defp interpret_named_value(name, value) do
    case value do
      [] ->       build_named_value(name, nil)
      [value] ->  build_named_value(name, value)
      _ ->        {:error, :unknown_format}
    end
  end

  #----------------------------------------------------------------------------'
  defp build_named_value(name, value) do
    case Regex.scan(~r/\w+[\w+]/, name) do
      [[key]] ->            {:ok, String.to_atom(key), value}
      [[key], [sub_key]] -> {:ok, String.to_atom(key), %{String.to_atom(sub_key) => value}}
      _ ->                  {:error, :unknown_format}
    end
  end

end