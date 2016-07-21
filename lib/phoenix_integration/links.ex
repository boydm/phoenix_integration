defmodule PhoenixIntegration.Links do

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
            _ -> nil
          end
        "/" <> _ ->
          case Floki.attribute(link, "href") do
            [^identifier] -> link
            _ -> nil
          end
        "http" <> _ ->
          case Floki.attribute(link, "href") do
            [^identifier] -> link
            _ -> nil
          end
        _ ->
          cond do
            # see if the identifier is in the links's text
            Floki.text(kids) =~ identifier -> link
            # all other cases fail
            true -> nil
          end
      end
    end)
    |> case do
      nil ->
        {err_type, err_ident} = case identifier do
          "#" <> id ->    {"id=", id}
          "/" <> _ ->     {"href=", identifier}
          "http" <> _ ->  {"href=", identifier}
          _ ->            {"text containing ", identifier}
        end
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
    {:ok, path, _method, _form} =
      PhoenixIntegration.Forms.find(html, identifier, method)
    {:ok, path}
  end

end