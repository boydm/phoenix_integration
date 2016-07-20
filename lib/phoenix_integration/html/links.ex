  defmodule PhoenixIntegration.Html.Links do

  import IEx

  #----------------------------------------------------------------------------
  # don't really care if there are multiple copies of the same link,
  # jsut that it is actually on the page
  def find( html, identifier, method \\ :get )
  def find( html, identifier, :get ) do
    identifier = String.strip(identifier)

    # scan all links, return the first where either the path or the content
    # is equal to the identifier
    Floki.find(html, "a")
    |> Enum.find_value( fn(link) ->
      {"a", _attribs, kids} = link

      case identifier do
        "#" <> id ->
          case Floki.attribute(link, "id") do
            [^id] -> link
            _ -> {"id=", id}
          end
        "/" <> _ ->
          case Floki.attribute(link, "href") do
            [^identifier] -> link
            _ -> {"href=", identifier}
          end
        "http" <> _ ->
          case Floki.attribute(link, "href") do
            [^identifier] -> link
            _ -> {"href=", identifier}
          end
        _ ->
          cond do
            # see if the identifier is in the links's text
            Floki.text(kids) =~ identifier -> link
            # all other cases fail
            true -> {"text containing ", identifier}
          end
      end
    end)
    |> case do
      {err_type, err_ident} ->
        msg = "Failed to find link \"#{identifier}\", :get in the response\n" <>
          "Expected to find an anchor with #{err_type}\"#{err_ident}\""
        raise msg
      link ->
        [path] = Floki.attribute(link, "href")
        {:ok, path}
    end

  end

  #--------------------------------------------------------
  def find( html, identifier, method ) do
    # scan all links, return the first where either the path or the content
    # is equal to the identifier
    Floki.find(html, "form")
    |> Enum.find_value( fn(form) ->
      {"form", _attribs, _kids} = form
      cond do
        # if a path was passed in, see if it equals the href
        Floki.attribute(form, "action") == [identifier] -> form
        # if an id was passed in, see if it equals form's id
        Floki.attribute(form, "id") == [identifier] -> form
        # if text, see if it in the form's text
        Floki.text(form) =~ identifier -> form
        # all other cases fail
        true -> false
      end
      |> verify_form_method(method)
    end )
    |> case do
      nil ->
        raise "Failed to find form \"#{identifier}\" in the response"
      form ->
        [path] = Floki.attribute(form, "action")
        {:ok, path}
    end
  end
  defp verify_form_method(false, _method), do: false
  defp verify_form_method(form, nil), do: form            # return form f no method requested
  defp verify_form_method(form, method) do
    case Floki.find( form, "input[name=\"_method\"]" ) do
      [] ->
        "post"
      [found_input] ->
        [found_method] = Floki.attribute(found_input, "value")
        found_method
    end
    |> case do
      ^method -> form
      _ -> false
    end
  end


end