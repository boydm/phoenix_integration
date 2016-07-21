defmodule PhoenixIntegration do


  defmacro __using__(_opts) do
    quote do
      import PhoenixIntegration.Assertions

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
        {:ok, href} = PhoenixIntegration.Links.find(conn.resp_body, identifer, method)

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
      def submit_form(conn = %Plug.Conn{}, identifier, fields, method \\ nil, form_finder \\ "form") do  
        # find the form
        {:ok, form_action, form_method, form} =
          PhoenixIntegration.Forms.find(conn.resp_body, identifier, method, form_finder)

        # build the data to send to the action pointed to by the form
        form_data = PhoenixIntegration.Forms.build_form_data(form, fields)

        # use ConnCase to call the form's handler. return the new conn
        case form_method do
          "post" ->
            post( conn, form_action, form_data )
          "put" -> 
            put( conn, form_action, form_data )
          "patch" -> 
            patch( conn, form_action, form_data )
          "get" ->
            get( conn, form_action, form_data )
        end
      end

      #----------------------------------------------------------------------------
      def follow_form(conn = %Plug.Conn{}, identifier, fields, method \\ nil, form_finder \\ "form") do
        submit_form(conn, identifier, fields, method, form_finder) |> follow_redirect
      end
    end # quote
  end # defmacro


end
