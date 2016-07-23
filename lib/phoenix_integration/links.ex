defmodule PhoenixIntegration.Links do
  use Phoenix.ConnTest
  
  @endpoint Application.get_env(:phoenix_integration, :endpoint)

  def get_end(), do: @endpoint

  #----------------------------------------------------------------------------
  def follow_redirect(conn = %Plug.Conn{}, max_redirects \\ 5) do
    if max_redirects == 0 do
      raise "Too Many Redirects"
    end
    case conn.status do
      302 ->
        # we want to use the returned conn for the redirects as it
        # contains state that might be needed
        [location] = Plug.Conn.get_resp_header(conn, "location")
        get(conn, location)
          |> follow_redirect(max_redirects - 1)
      _ -> conn
    end
  end

  #----------------------------------------------------------------------------
  def follow_path(conn = %Plug.Conn{}, path) do
    get(conn, path) |> follow_redirect
  end

  #----------------------------------------------------------------------------
  def click_link(conn = %Plug.Conn{}, identifer, method \\ "get") do
    {:ok, href} = find_html_link(conn.resp_body, identifer, method)

    case to_string(method) do
      "get" ->
        get( conn, href )
      "post" ->
        post( conn, href )
      "put" -> 
        put( conn, href )
      "patch" -> 
        patch( conn, href )
      "delete" ->
        delete( conn, href )
    end
  end

  #----------------------------------------------------------------------------
  def follow_link(conn = %Plug.Conn{}, indentifer, method \\ "get") do
    click_link(conn, indentifer, method) |> follow_redirect
  end


  #----------------------------------------------------------------------------
  # don't really care if there are multiple copies of the same link,
  # jsut that it is actually on the page
  def find_html_link( html, identifier, method \\ "get" )
  def find_html_link( html, identifier, :get ), do: find_html_link( html, identifier, "get" )
  def find_html_link( html, identifier, "get" ) do
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

  #============================================================================
  # private below


  #--------------------------------------------------------
  def find_html_link( html, identifier, method ) do
    {:ok, path, _method, _form} =
      PhoenixIntegration.Forms.find_html_form(html, identifier, method)
    {:ok, path}
  end

end