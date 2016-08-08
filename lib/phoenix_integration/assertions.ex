defmodule PhoenixIntegration.Assertions do

  @moduledoc """
  Functions to assert/refute the response content of a conn without interrupting the
  chain of actions in an integration test.

  Each function takes a conn and a set of conditions to test. Each condition is tested
  and, if they all pass, the function returns the passed-in conn unchanged. If any
  condition fails, the function raises an appropriate error.

  This is intended to be used in a (possibly long) chain of piped functions that
  exercises a set of functionality in your application.

  ### Example
      test "Basic page flow", %{conn: conn} do
        # get the root index page
        get( conn, page_path(conn, :index) )
        # click/follow through the various about pages
        |> follow_link( "About Us" )
        |> assert_response( status: 200, path: about_path(conn, :index) )
        |> follow_link( "Contact" )
        |> assert_response( content_type: "text/html" )
        |> follow_link( "Privacy" )
        |> assert_response( html: "Privacy Policy" )
        |> follow_link( "Home" )
        |> assert_response( status: 200, path: page_path(conn, :index) )
      end
  """

#  import IEx

  defmodule ResponseError do
    defexception [message: "#{IO.ANSI.red}The conn's response was not formed as expected\n"]
  end

  @doc """
  Asserts a set of conditions against the response fields of a conn. Returns the conn on success
  so that it can be used in the next integration call.

  ### Parameters
     * `conn` should be a conn returned from a previous request
      should point to the path being redirected to.
    * `conditions` a list of conditions to test against. Conditions can include:
      * `:status` checks that `conn.status` equals the given numeric value
      * `:content_type` the conn's content-type header should contain the given text. Typical
        values are `"text/html"` or `"applicaiton/json"`
      * `:body` conn.resp_body should contain the given text. Does not check the content_type.
      * `:html` checks that content_type is html, then looks for the given text in the body.
      * `:json` checks that content_type is json, then checks that the json data equals the given map.
      * `:path` the route rendered into the conn must equal the given path (or uri).
      * `:uri` same as `:path`
      * `:redirect` checks that `conn.status` is 302 and that the path in the "location" redirect
        header equals the given path.
      * `:to` same as `:redirect`
      * `:assigns` checks that conn.assigns contains the given values, which could be in the form of `%{key => value}`
        or `[{key, value}]`

  Conditions can be used multiple times within a single call to `assert_response`. This can be useful
  to look for multiple text strings in the body.

  Example

      # test a rendered page
      assert_response( conn,
        status:   200,
        path:     page_path(conn, :index),
        html:     "Some Content",
        html:     "More Content",
        assigns:  %{current_user_id: user.id}
      )

      # test a redirection
      assert_response( conn, to: page_path(conn, :index) )
  """
  def assert_response(conn = %Plug.Conn{}, conditions) do
    Enum.each(conditions, fn({condition, value}) ->
      case condition do
        :status ->        assert_status(conn, value)
        :content_type ->  assert_content_type(conn, value)
        :body ->          assert_body(conn, value)
        :html ->          assert_body_html(conn, value)
        :json ->          assert_body_json( conn, value )
        :uri ->           assert_uri(conn, value)
        :path ->          assert_uri(conn, value, :path)
        :redirect ->      assert_redirect(conn, value)
        :to ->            assert_redirect(conn, value, :to)
        :assigns ->       assert_assigns(conn, value)
      end
    end)
    conn
  end

  @doc """
  Refutes a set of conditions for the response fields in a conn. Returns the conn on success
  so that it can be used in the next integration call.

  ### Parameters
     * `conn` should be a conn returned from a previous request
      should point to the path being redirected to.
    * `conditions` a list of conditions to test against. Conditions can include:
      * `:status` checks that `conn.status` is not the given numeric value
      * `:content_type` the conn's content-type header should not contain the given text. Typical
        values are `"text/html"` or `"applicaiton/json"`
      * `:body` conn.resp_body should not contain the given text. Does not check the content_type.
      * `:html` checks if content_type is html. If it is, it then checks that the given text is not in the body.
      * `:json` checks if content_type is json, then checks that the json data does not equal the given map.
      * `:path` the route rendered into the conn must not equal the given path (or uri).
      * `:uri` same as `:path`
      * `:redirect` checks if `conn.status` is 302. If it is, then checks that the path in the "location" redirect
        header is not the given path.
      * `:to` same as `:redirect`
      * `:assigns` checks that conn.assigns does not contain the given values, which could be in the form of `%{key: value}`
        or `[{:key, value}]`

  `refute_response` is often used in conjuntion with `assert_response` to form a complete condition check.

  Example

      # test a rendered page
      follow_path( conn, page_path(conn, :index) )
      |> assert_response(
          status: 200,
          path:   page_path(conn, :index)
          html:   "Good Content"
        )
      |> refute_response( body: "Invalid Content" )
  """
  def refute_response(conn = %Plug.Conn{}, conditions) do
    Enum.each(conditions, fn({condition, value}) ->
      case condition do
        :status ->        refute_status(conn, value)
        :content_type ->  refute_content_type(conn, value)
        :body ->          refute_body(conn, value)
        :html ->          refute_body_html(conn, value)
        :json ->          refute_body_json( conn, value )
        :uri ->           refute_uri(conn, value)
        :path ->          refute_uri(conn, value, :path)
        :redirect ->      refute_redirect(conn, value)
        :to ->            refute_redirect(conn, value, :to)
        :assigns ->       refute_assigns(conn, value)
      end
    end)
    conn
  end


  #----------------------------------------------------------------------------
  defp assert_assigns(conn, expected, err_type \\ :assigns)
  defp assert_assigns(conn, expected, err_type) when is_map(expected) do
    Enum.each(expected, fn({key, value}) -> 
      if conn.assigns[key] != value do
        # raise an appropriate error
        msg = error_msg_type( conn, err_type ) <>
          error_msg_expected( "conn.assigns to contain: " <> inspect(expected) ) <>
          error_msg_found( inspect(conn.assigns) )
        raise %ResponseError{ message: msg }
      end
    end)
  end
  defp assert_assigns(conn, expected, err_type) when is_list(expected), do:
    assert_assigns(conn, Enum.into(expected, %{}), err_type )


  #----------------------------------------------------------------------------
  defp refute_assigns(conn, expected, err_type \\ :assigns)
  defp refute_assigns(conn, expected, err_type) when is_map(expected) do
    Enum.each(expected, fn({key, value}) -> 
      if conn.assigns[key] != value do
        # raise an appropriate error
        msg = error_msg_type( conn, err_type ) <>
          error_msg_expected( "conn.assigns to NOT contain: " <> inspect(expected) ) <>
          error_msg_found( inspect(conn.assigns) )
        raise %ResponseError{ message: msg }
      end
    end)
  end
  defp refute_assigns(conn, expected, err_type) when is_list(expected), do:
    assert_assigns(conn, Enum.into(expected, %{}), err_type )


  #----------------------------------------------------------------------------
  defp assert_uri(conn, expected, err_type \\ :uri) do
    # parse the expected uri
    uri = URI.parse expected

    # prepare the path and query data
    {uri_path, conn_path} = case uri.path do
      nil -> {nil, nil}
      _path -> {uri.path, conn.request_path}
    end
    {uri_query, conn_query} = case uri.query do
      nil -> {nil, nil}
      _query ->
        # decode the queries to get order independence
        {URI.decode_query( uri.query ), URI.decode_query( conn.query_string )}
    end

    # The main test
    pass = cond do
      uri_path && uri_query -> (uri_path == conn_path) && (uri_query == conn_query)
      uri_path -> uri_path == conn_path
      uri_query -> uri_query == conn_query
    end

    # raise or not as appropriate
    if pass do
      conn
    else
      # raise an appropriate error
      msg = error_msg_type( conn, err_type ) <>
        error_msg_expected( expected ) <>
        error_msg_found( conn_request_path(conn) )
      raise %ResponseError{ message: msg }
    end
  end

  #----------------------------------------------------------------------------
  defp refute_uri(conn, expected, err_type \\ :uri) do
    # parse the expected uri
    uri = URI.parse expected

    # prepare the path and query data
    {uri_path, conn_path} = case uri.path do
      nil -> {nil, nil}
      _path -> {uri.path, conn.request_path}
    end
    {uri_query, conn_query} = case uri.query do
      nil -> {nil, nil}
      _query ->
        # decode the queries to get order independence
        {URI.decode_query( uri.query ), URI.decode_query( conn.query_string )}
    end

    # The main test
    pass = cond do
      uri_path && uri_query -> (uri_path != conn_path) || (uri_query != conn_query)
      uri_path -> uri_path != conn_path
      uri_query -> uri_query != conn_query
    end

    # raise or not as appropriate
    if pass do
      conn
    else
      # raise an appropriate error
      msg = error_msg_type( conn, err_type ) <>
        error_msg_expected( "path to NOT be:" <> conn_request_path(conn) ) <>
        error_msg_found( conn_request_path(conn) )
      raise %ResponseError{ message: msg }
    end
  end

  #----------------------------------------------------------------------------
  defp assert_redirect(conn, expected, err_type \\ :redirect) do
    assert_status( conn, 302 )
    case Plug.Conn.get_resp_header(conn, "location") do
      [^expected] -> conn
      [to] ->
        msg = error_msg_type( conn, err_type ) <>
          error_msg_expected( to_string(expected) ) <>
          error_msg_found( to_string(to) )
        raise %ResponseError{ message: msg }
    end
  end

  #----------------------------------------------------------------------------
  defp refute_redirect(conn, expected, err_type \\ :redirect) do
    case conn.status do
      302 ->
        case Plug.Conn.get_resp_header(conn, "location") do
          [^expected] ->
            msg = error_msg_type( conn, err_type ) <>
              error_msg_expected( "to NOT redirect to: " <> to_string(expected) ) <>
              error_msg_found( "redirect to: " <> to_string(expected) )
            raise %ResponseError{ message: msg }
          [_to] -> conn
        end
      _other -> conn
    end
  end

  #----------------------------------------------------------------------------
  defp assert_body_html(conn, expected, err_type \\ :html) do
    assert_content_type(conn, "text/html", err_type)
    |> assert_body( expected, err_type )
  end

  #----------------------------------------------------------------------------
  defp refute_body_html(conn, expected, err_type \\ :html) do
    # slightly different than asserting body_html
    # good if not html content
    case Plug.Conn.get_resp_header(conn, "content-type") do
      [] -> conn
      [header] ->
        cond do
          header =~ "text/html"->
            refute_body( conn, expected, err_type )
          true -> conn
        end
    end
  end

  #----------------------------------------------------------------------------
  defp assert_body_json(conn, expected, err_type \\ :json) do
    assert_content_type(conn, "application/json", err_type)
    case Poison.decode!( conn.resp_body ) do
      ^expected -> conn
      data ->
        msg = error_msg_type( conn, err_type ) <>
          error_msg_expected( inspect(expected) ) <>
          error_msg_found( inspect(data) )
        raise %ResponseError{ message: msg }
    end
  end

  #----------------------------------------------------------------------------
  defp refute_body_json(conn, expected, err_type \\ :json) do
    # similar to refute body html, ok if content isn't json
    case Plug.Conn.get_resp_header(conn, "content-type") do
      [] -> conn
      [header] ->
        cond do
          header =~ "json"->
            case Poison.decode!( conn.resp_body ) do
              ^expected ->
                msg = error_msg_type( conn, err_type ) <>
                  error_msg_expected( "to NOT find " <> inspect(expected) ) <>
                  error_msg_found( inspect(expected) )
                raise %ResponseError{ message: msg }
              _data -> conn
            end
          true -> conn
        end
    end
  end

  #----------------------------------------------------------------------------
  defp assert_body(conn, expected, err_type \\ :body) do
    if conn.resp_body =~ expected do
      conn
    else
      msg = error_msg_type( conn, err_type ) <>
        error_msg_expected( "to find \"#{expected}\"" ) <>
        error_msg_found( "Not in the response body\n" ) <>
        IO.ANSI.yellow <>
        conn.resp_body
      raise %ResponseError{ message: msg }
    end
  end

  #----------------------------------------------------------------------------
  defp refute_body(conn, expected, err_type \\ :body) do
    if conn.resp_body =~ expected do
      msg = error_msg_type( conn, err_type ) <>
        error_msg_expected( "NOT to find \"#{expected}\"" ) <>
        error_msg_found( "in the response body\n" ) <>
        IO.ANSI.yellow <>
        conn.resp_body
      raise %ResponseError{ message: msg }
    else
      conn
    end
  end

  #----------------------------------------------------------------------------
  defp assert_status(conn, status, err_type \\ :status) do
    case conn.status do
      ^status -> conn
      other ->
        msg = error_msg_type( conn, err_type ) <>
          error_msg_expected( to_string(status) ) <>
          error_msg_found( to_string(other) )
        raise %ResponseError{ message: msg }
    end
  end

  #----------------------------------------------------------------------------
  defp refute_status(conn, status, err_type \\ :status) do
    case conn.status do
      ^status ->
        msg = error_msg_type( conn, err_type ) <>
          error_msg_expected( "NOT " <> to_string(status) ) <>
          error_msg_found( to_string(status) )
        raise %ResponseError{ message: msg }
      _other -> conn
    end
  end

  #----------------------------------------------------------------------------
  defp assert_content_type(conn, expected_type, err_type \\ :content_type) do
    case Plug.Conn.get_resp_header(conn, "content-type") do
      [] -> 
        # no content type header was found
        msg = error_msg_type( conn, err_type ) <>
          error_msg_expected("content-type header of \"#{expected_type}\"") <>
          error_msg_found( "No content-type header was found" )
        raise %ResponseError{ message: msg }
      [header] ->
        cond do
          header =~ expected_type->
            # success case
            conn
          true ->
            # there was a content type header, but the wrong one
            msg = error_msg_type( conn, err_type ) <>
              error_msg_expected("content-type including \"#{expected_type}\"") <>
              error_msg_found( "\"#{header}\"" )
            raise %ResponseError{ message: msg }
        end
    end
  end

  #----------------------------------------------------------------------------
  defp refute_content_type(conn, expected_type, err_type \\ :content_type) do
    case Plug.Conn.get_resp_header(conn, "content-type") do
      [] -> conn
      [header] ->
        cond do
          header =~ expected_type->
            # the refuted content_type header was found
            msg = error_msg_type( conn, err_type ) <>
              error_msg_expected("content-type to NOT be \"#{expected_type}\"") <>
              error_msg_found( "\"#{header}\"" )
            raise %ResponseError{ message: msg }
          true -> conn
        end
    end
  end

  #----------------------------------------------------------------------------
  defp error_msg_type(conn, type) do
    "#{IO.ANSI.red}The conn's response was not formed as expected\n" <>
    "#{IO.ANSI.green}Error verifying #{IO.ANSI.cyan}:#{type}\n" <>
    "#{IO.ANSI.green}Request path: #{IO.ANSI.yellow}#{conn_request_path(conn)}\n" <>
    "#{IO.ANSI.green}Request method: #{IO.ANSI.yellow}#{conn.method}\n" <>
    "#{IO.ANSI.green}Request params: #{IO.ANSI.yellow}#{inspect(conn.params)}\n"
  end
  #----------------------------------------------------------------------------
  defp error_msg_expected(msg) do
    "#{IO.ANSI.green}Expected: #{IO.ANSI.red}#{msg}\n"
  end
  #----------------------------------------------------------------------------
  defp error_msg_found(msg) do
    "#{IO.ANSI.green}Found: #{IO.ANSI.red}#{msg}\n"
  end

  #----------------------------------------------------------------------------
  defp conn_request_path(conn) do
    conn.request_path <> 
    case conn.query_string do
      nil -> ""
      "" -> ""
      query -> "?" <> query
    end
  end

end



































