defmodule PhoenixIntegration.Html.Forms do
  import IEx

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



end