defmodule PhoenixIntegration.Requests do
  use Phoenix.ConnTest
  alias PhoenixIntegration.Form.{TreeCreation, TreeEdit, TreeFinish}
  alias PhoenixIntegration.Form

  @moduledoc """
  A set of functions intended to compliment the regular Phoenix.ConnTest utilities
  of `get`, `post`, `put`, `patch`, and `delete`.

  Each request function takes a conn and a set of data telling it what to do. Then it
  requests one or more paths from your phoenix application, transforming the
  conn each time. The final conn is returned.

  All the functions except `follow_path` and `follow_redirect` examine the html
  conntent of the incoming conn to find a link or form to use. In this way, you
  can both confirm that content exists in rendered pages and take actions as
  the user would.

  This is intended to be used as a (possibly long) chain of piped functions that
  exercises a set of functionality in your application.

  ### Examples
      test "Basic page flow", %{conn: conn} do
        # get the root index page
        get( conn, page_path(conn, :index) )
        # click/follow through the various about pages
        |> follow_link( "About Us" )
        |> follow_link( "Contact" )
        |> follow_link( "Privacy" )
        |> follow_link( "Terms of Service" )
        |> follow_link( "Home" )
        |> assert_response( status: 200, path: page_path(conn, :index) )
      end

      test "Create new user", %{conn: conn} do
        # get the root index page
        get( conn, page_path(conn, :index) )
        # create the new user
        |> follow_link( "Sign Up" )
        |> follow_form( %{ user: %{
              name: "New User",
              email: "user@example.com",
              password: "test.password",
              confirm_password: "test.password"
            }} )
        |> assert_response(
            status: 200,
            path: page_path(conn, :index),
            html: "New User" )
      end
  """

  @endpoint Application.get_env(:phoenix_integration, :endpoint)

  # ----------------------------------------------------------------------------
  @doc """
  Given a conn who's response is a redirect, `follow_redirect` calls the path indicated
  by the "location" response header and returns the conn from that call.

  ### Parameters
    * `conn` A conn whose status 302, which is a redirect. The conn's location header
      should point to the path being redirected to.
    * `max_redirects` The maximum number of recirects to follow. Defaults to `5`;

  Any incoming `conn.status` other than 302 causes `follow_redirect` to take no
  action and return the incoming conn for further processing.
  """
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

      _ ->
        conn
    end
  end

  # ----------------------------------------------------------------------------
  @doc """
  Similar to a standard get/post/put/patch/delete call in a ConnTest except that
  `follow_path` follows any redirects returned in the conn's response header.

  Unlike the rest of the functions in this module, `follow_path` ignores the
  conn.resp_body and simply uses the given path.

  ### Parameters
    * `conn` A conn that has been set up to work in the test environment.
      Could be the conn originally passed in to the test;
    * `path` A path that works with your router;
    * `opts` A map of additional options
      * `:method` - method to use when requesting the path. Defaults to `"get"`;
      * `:max_redirects` - Maximum number of redirects to follow. Defaults to `5`;

  ### Example:
      follow_path( conn, thing_path(conn, :index) )
      |> assert_response( status: 200, path: think_path(conn, :index) )
  """
  def follow_path(conn, path, opts \\ %{})

  def follow_path(conn = %Plug.Conn{}, path, opts) when is_list(opts) do
    follow_path(conn, path, Enum.into(opts, %{}))
  end

  def follow_path(conn = %Plug.Conn{}, path, opts) do
    opts =
      Map.merge(
        %{
          method: "get",
          max_redirects: 5
        },
        opts
      )

    request_path(conn, path, opts.method)
    |> follow_redirect(opts.max_redirects)
  end

  # ----------------------------------------------------------------------------
  @doc """
  Finds a link in conn.resp_body, requests it as if the user had clicked on it,
  and returns the resulting conn.

  ### Parameters
    * `conn` should be a conn returned from a previous request that rendered some html. The
      functions are designed to pass the conn from one call into the next via pipes.
    * `identifier` indicates which link to find in the html. Valid values can be in the following
      forms:
        * `"/some/path"` specify the link's href starting with a `"/"` character
        * `"http://www.example.com/some/uri"`, specify the href as full uri starting with either `"http"` or `"https"`
        * `"#element-id"` specify the html element id of the link you are looking for. Must start
          start with the `"#"` character (same as css id specifier).
        * `"Some Text"` specify text contained within the link you are looking for.
    * `opts` A map of additional options
      * `:method` - method to use when requesting the path. Defaults to `"get"`;

  `click_link` does __not__ follow any redirects returned by the request. This allows
  you to explicitly check that the redirect is correct. Use `follow_redirect` to request
  the location redirected to, or just use `follow_link` to do it in one call.

  If the link is not found in the body, `click_link` raises an error.

  ### Examples:

      # click a link specified by path or uri
      get( conn, thing_path(conn, :index) )
      |> click_link( page_path(conn, :index) )

      # click a link specified by html id with a non-get method
      get( conn, thing_path(conn, :index) )
      |> click_link( "#link-id", method: :delete )

      # click a link containing the given text
      get( conn, thing_path(conn, :index) )
      |> click_link( "Settings" )

      # test a redirect and continue
      get( conn, thing_path(conn, :index) )
      |> click_link( "something that redirects to new" )
      |> assert_response( status: 302, to: think_path(conn, :new) )
      |> follow_redirect()
      |> assert_response( status: 200, path: think_path(conn, :new) )

  ### Links that don't use the :get method

  When Phoneix.Html renders a link, it usually generates an `<a>` tag. However, if you
  specify a method other than :get, then Phoenix generates html looks like a link, but
  is really a form using the method. This is why you must specify the method used in `opts`
  if you used anything other than the standard :get in your link.

      # follow a non-get link
      click_link( conn, thing_path(conn, :delete), method: :delete )
  """
  def click_link(conn, identifer, opts \\ %{})

  def click_link(conn = %Plug.Conn{}, path, opts) when is_list(opts) do
    click_link(conn, path, Enum.into(opts, %{}))
  end

  def click_link(conn = %Plug.Conn{}, identifer, opts) do
    opts = Map.merge(%{method: "get"}, opts)

    {:ok, href} = find_html_link(conn.resp_body, identifer, opts.method)
    request_path(conn, href, opts.method)
  end

  # ----------------------------------------------------------------------------
  @doc """
  Finds a link in conn.resp_body, requests it as if the user had clicked on it,
  follows any redirects, and returns the resulting conn.

  ### Parameters
    * `conn` should be a conn returned from a previous request that rendered some html. The
      functions are designed to pass the conn from one call into the next via pipes.
    * `identifier` indicates which link to find in the html. Valid values can be in the following
      forms:
        * `"/some/path"` specify the link's href starting with a `"/"` character
        * `"http://www.example.com/some/uri"`, specify the href as full uri starting with either `"http"` or `"https"`
        * `"#element-id"` specify the html element id of the link you are looking for. Must start
          start with the `"#"` character (same as css id specifier).
        * `"Some Text"` specify text contained within the link you are looking for.
    * `opts` A map of additional options
      * `:method` - method to use when requesting the path. Defaults to `"get"`;
      * `:max_redirects` - Maximum number of redirects to follow. Defaults to `5`;

  This is similar to `click_link`, except that it follows returned redirects. This
  is very useful during integration tests as you typically want to emulate what the
  user is really doing. You will probably use `follow_link` more than `click_link`.

  If the link is not found in the body, `follow_link` raises an error.

  ### Example:
        # click through several pages that should point to each other
        get( conn, thing_path(conn, :index) )
        |> follow_link( "#settings" )
        |> follow_link( "Cancel" )
        |> assert_response( path: thing_path(conn, :index) )

  ### Links that don't use the :get method

  When Phoneix.Html renders a link, it usually generates an `<a>` tag. However, if you
  specify a method other than :get, then Phoenix generates html looks like a link, but
  is really a form using the method. This is why you must specify the method used in `opts`
  if you used anything other than the standard :get in your link.

      # follow a non-get link
      follow_link( conn, thing_path(conn, :delete), method: :delete )
  """
  def follow_link(conn, indentifer, opts \\ %{})

  def follow_link(conn = %Plug.Conn{}, indentifer, opts) when is_list(opts) do
    follow_link(conn, indentifer, Enum.into(opts, %{}))
  end

  def follow_link(conn = %Plug.Conn{}, indentifer, opts) do
    opts =
      Map.merge(
        %{
          method: "get",
          max_redirects: 5
        },
        opts
      )

    click_link(conn, indentifer, opts)
    |> follow_redirect(opts.max_redirects)
  end

  # ----------------------------------------------------------------------------
  @doc """
  Finds a button in conn.resp_body and acts as if the user had clicked on it,
  and returns the resulting conn.

  This is very similar to `click_link` except that it looks for button tags
  as rendered by PhoenixHtml.

  ### Parameters
    * `conn` should be a conn returned from a previous request that rendered some html. The
      functions are designed to pass the conn from one call into the next via pipes.
    * `identifier` indicates which link to find in the html. Valid values can be in the following
      forms:
        * `"/some/path"` specify the link's href starting with a `"/"` character
        * `"http://www.example.com/some/uri"`, specify the href as full uri starting with either `"http"` or `"https"`
        * `"#element-id"` specify the html element id of the link you are looking for. Must start
          start with the `"#"` character (same as css id specifier).
        * `"Some Text"` specify text contained within the link you are looking for.
    * `opts` A map of additional options
      * `:method` - method to use when requesting the path. Defaults to `"get"`;

  `click_button` does __not__ follow any redirects returned by the request. This allows
  you to explicitly check that the redirect is correct. Use `follow_redirect` to request
  the location redirected to, or just use `follow_link` to do it in one call.

  If the link is not found in the body, `click_button` raises an error.

  ### Examples:

      # click a link specified by path or uri
      get( conn, thing_path(conn, :index) )
      |> click_button( page_path(conn, :index) )

      # click a link specified by html id with a non-get method
      get( conn, thing_path(conn, :index) )
      |> click_button( "#button_id", method: :delete )

      # click a link containing the given text
      get( conn, thing_path(conn, :index) )
      |> click_button( "Settings" )

      # test a redirect and continue
      get( conn, thing_path(conn, :index) )
      |> click_button( "something that redirects to new" )
      |> assert_response( status: 302, to: think_path(conn, :new) )
      |> follow_redirect()
      |> assert_response( status: 200, path: think_path(conn, :new) )

  Returns the transformed conn after submitting the request.

  ### Button request methods that don't use the :get method

  Unlike trying to click anchor tags, Phoenix always puts the method in button tags as an attribute.

  This means that if you want to match agains tags with a non-get method you can, but you don't
  really need to.
  """
  def click_button(conn, identifer, opts \\ %{})

  def click_button(conn = %Plug.Conn{}, path, opts) when is_list(opts) do
    click_button(conn, path, Enum.into(opts, %{}))
  end

  def click_button(conn = %Plug.Conn{}, identifer, opts) do
    # setting the method to nil means get it out of data-method
    opts = Map.merge(%{method: nil}, opts)

    {:ok, href, method} = find_html_button(conn.resp_body, identifer, opts.method)
    request_path(conn, href, method)
  end

  # ----------------------------------------------------------------------------
  @doc """
  Finds a button in conn.resp_body, acts as if the user had clicked on it,
  follows any redirects, and returns the resulting conn.

  This is very similar to `follow_link` except that it looks for button tags
  as rendered by PhoenixHtml.

  ### Parameters
    * `conn` should be a conn returned from a previous request that rendered some html. The
      functions are designed to pass the conn from one call into the next via pipes.
    * `identifier` indicates which link to find in the html. Valid values can be in the following
      forms:
        * `"/some/path"` specify the link's href starting with a `"/"` character
        * `"http://www.example.com/some/uri"`, specify the href as full uri starting with either `"http"` or `"https"`
        * `"#element-id"` specify the html element id of the link you are looking for. Must start
          start with the `"#"` character (same as css id specifier).
        * `"Some Text"` specify text contained within the link you are looking for.
    * `opts` A map of additional options
      * `:method` - method to use when requesting the path. Defaults to `"get"`;
      * `:max_redirects` - Maximum number of redirects to follow. Defaults to `5`;

  If the link is not found in the body, `follow_button` raises an error.

  ### Example:
        # click through several pages that should point to each other
        get( conn, thing_path(conn, :index) )
        |> follow_button( "#settings_button" )
        |> follow_button( "Cancel" )
        |> assert_response( path: thing_path(conn, :index) )

  ### Button request methods that don't use the :get method

  Returns the transformed conn after submitting, then following the request.

  Unlike trying to follow anchor tags, Phoenix always puts the method in button tags as an attribute.

  This means that if you want to match agains tags with a non-get method you can, but you don't
  really need to.
  """
  def follow_button(conn, indentifer, opts \\ %{})

  def follow_button(conn = %Plug.Conn{}, indentifer, opts) when is_list(opts) do
    follow_button(conn, indentifer, Enum.into(opts, %{}))
  end

  def follow_button(conn = %Plug.Conn{}, indentifer, opts) do
    opts =
      Map.merge(
        %{
          max_redirects: 5
        },
        opts
      )

    click_button(conn, indentifer, opts)
    |> follow_redirect(opts.max_redirects)
  end

  # ----------------------------------------------------------------------------
  @doc """
  Finds a form in conn.resp_body, fills out the fields with the given
  data, requests the form's action and returns the resulting conn.

  ### Parameters
    * `conn` should be a conn returned from a previous request that rendered some html. The
      functions are designed to pass the conn from one call into the next via pipes.
    * `fields` a map of fields and data to be written into the form before submitting its action.
    * `opts` A map of additional options
      * `identifier` indicates which link to find in the html. Defaults to `nil`. Valid values can be
        in the following forms:
          * `"/some/path"` specify the link's href starting with a `"/"` character
          * `"http://www.example.com/some/uri"`, specify the href as full uri starting with either `"http"` or `"https"`
          * `"#element-id"` specify the html element id of the link you are looking for. Must start
            start with the `"#"` character (same as css id specifier).
          * `"Some Text"` specify text contained within the link you are looking for.
      * `:method` - restricts the forms searched to those whose action uses the given
      method (such as "post" or "put"). Defaults to `nil`;
      * `:finder` - finding string passed to `Floki.find`. Defaults to `"form"`

  If no `opts.identifier` is specified, the first form that makes sense is used. Unless you
  have multiple forms on your page, this often is the most understandable pattern.

  If no appropriate form is found, `submit_form` raises an error.

  Any redirects are __not__ followed.

  ### Example:
        # fill out a form and submit it
        get( conn, thing_path(conn, :edit, thing) )
        |> submit_form( %{ thing: %{
            name: "Updated Name",
            some_count: 42
          }})
        |> assert_response( status: 302, to: thing_path(conn, :show, thing) )
  """
  def submit_form(conn, fields, opts \\ %{})

  def submit_form(conn = %Plug.Conn{}, fields, opts) when is_list(opts) do
    submit_form(conn, fields, Enum.into(opts, %{}))
  end

  def submit_form(conn = %Plug.Conn{}, fields, opts) do
    opts =
      Map.merge(
        %{
          identifier: nil,
          method: nil,
          finder: "form"
        },
        opts
      )

    # find the form
    {:ok, form_action, form_method, form} =
      find_html_form(conn.resp_body, opts.identifier, opts.method, opts.finder)

    # build the data to send to the action pointed to by the form
    form_data = build_form_data(form, fields)

    # use ConnCase to call the form's handler. return the new conn
    request_path(conn, form_action, form_method, form_data)
  end



  # ----------------------------------------------------------------------------
  @doc """
  Finds a form in conn.resp_body, fills out the fields with the given
  data, requests the form's action, follows any redirects and returns the resulting conn.

  Similar to `submit_form`, except that it does follow redirects.

  ### Parameters
    * `conn` should be a conn returned from a previous request that rendered some html. The
      functions are designed to pass the conn from one call into the next via pipes.
    * `fields` a map of fields and data to be written into the form before submitting its action. The data can take one of three forms:
      * Most frequently, it's a string.
      * It can be a list of strings. That's used when a set of tags in the form have names ending with `[]` to tell Phoenix to create a list value. See the example below.
      * It can be an Elixir struct like `DateTime` or [`%Plug.Upload`](https://hexdocs.pm/plug/Plug.Upload.html).
        In that case, the fields within the struct are used to find matching tags (by name) in the form. Fields that don't match are ignored. See the example below.
    * `opts` A map of additional options
      * `identifier` indicates which link to find in the html. Defaults to `nil`. Valid values can be
        in the following forms:
          * `"/some/path"` specify the link's href starting with a `"/"` character
          * `"http://www.example.com/some/uri"`, specify the href as full uri starting with either `"http"` or `"https"`
          * `"#element-id"` specify the html element id of the link you are looking for. Must start
            start with the `"#"` character (same as css id specifier).
          * `"Some Text"` specify text contained within the link you are looking for.
      * `:method` - restricts the forms searched to those whose action uses the given
      method (such as "post" or "put"). Defaults to `nil`;
      * `:finder` - finding string passed to `Floki.find`. Defaults to `"form"`

  If no `opts.identifier` is specified, the first form that makes sense is used. Unless you
  have multiple forms on your page, this often is the most understandable pattern.

  If no appropriate form is found, `follow_form` raises an error.

  ### Example:
        upload = %Plug.Upload{
          content_type: "image/jpg",
          path: "/var/mytests/photo.jpg",
          filename: "photo.jpg"}
  
        # fill out a form and submit it
        get( conn, thing_path(conn, :edit, thing) )
        |> follow_form( %{ thing: %{
            name: "Updated Name",
            some_count: 42,
            comments: ["first", "second"],
            photo: upload
          }})
        |> assert_response( status: 200, path: thing_path(conn, :show, thing) )

  In this example, the form would contain list-creating HTML like this:

       <input id="comment1" type="text" name="thing[comments][]" value="">
       <input id="comment2" type="text" name="thing[comments][]" value="">

  The photo part of the form would probably have been created like this:

       <%= file_input f, :photo %>  
        
  """
  def follow_form(conn, fields, opts \\ %{})

  def follow_form(conn = %Plug.Conn{}, fields, opts) when is_list(opts) do
    follow_form(conn, fields, Enum.into(opts, %{}))
  end

  def follow_form(conn = %Plug.Conn{}, fields, opts) do
    opts = Map.merge(%{max_redirects: 5}, opts)

    submit_form(conn, fields, opts)
    |> follow_redirect(opts.max_redirects)
  end

  # ----------------------------------------------------------------------------
  @doc """
  Convenience function to find and return a form in a conn.resp_body.

  Returns the form as a map.

  ### Parameters
    * `conn` should be a conn returned from a previous request that rendered some html. The
      functions are designed to pass the conn from one call into the next via pipes.
    * `opts` A map of additional options
      * `identifier` indicates which link to find in the html. Defaults to `nil`. Valid values can be
        in the following forms:
          * `"/some/path"` specify the link's href starting with a `"/"` character
          * `"http://www.example.com/some/uri"`, specify the href as full uri starting with either `"http"` or `"https"`
          * `"#element-id"` specify the html element id of the link you are looking for. Must start
            start with the `"#"` character (same as css id specifier).
          * `"Some Text"` specify text contained within the link you are looking for.
      * `:method` - restricts the forms searched to those whose action uses the given
      method (such as "post" or "put"). Defaults to `nil`;
      * `:finder` - finding string passed to `Floki.find`. Defaults to `"form"`

  If no `opts.identifier` is specified, the first form that makes sense is used. Unless you
  have multiple forms on your page, this often is the most understandable pattern.

  If no appropriate form is found, `fetch_form` raises an error.

  If you have more than one form in the response, you will probably need to use the identifier options
  similar to what how you specify a form for submit_form or follow_form.

  ### Example:
        # get the value from a form on the page.
        fetch_form( conn )

        ## returns something like...
        %{
          id:     "some_id",
          method: "put",
          action: "/some/action"
          inputs: %{
            user: %{
              first_name: "Jane",
              last_name:  "Doe"
            }
          }
        }

  Note: this fetches the form as it is in the response. It will not show you updates you are making as
  you prepare for the next submission.
  """
  def fetch_form(conn, opts \\ %{})

  def fetch_form(conn = %Plug.Conn{}, opts) when is_list(opts) do
    fetch_form(conn, Enum.into(opts, %{}))
  end

  def fetch_form(%Plug.Conn{} = conn, %{} = opts) do
    opts =
      Map.merge(
        %{
          identifier: nil,
          method: nil,
          finder: "form"
        },
        opts
      )

    # find the form
    {:ok, _form_action, _form_method, raw_form} =
      find_html_form(conn.resp_body, opts.identifier, opts.method, opts.finder)

    # fetch the main form attributes
    form = %{
      method: form_method(raw_form),
      inputs: tree_with_emitted_warnings(raw_form) |> TreeFinish.to_action_params
    }

    form =
      case Floki.attribute(raw_form, "action") do
        [action] -> Map.put(form, :action, action)
        _ -> form
      end

    case Floki.attribute(raw_form, "id") do
      [id] -> Map.put(form, :id, id)
      _ -> form
    end
  end

  # ----------------------------------------------------------------------------
  @doc """
  Calls a function and follows the any redirects in the returned `conn`.
  If the function returns anything other than a `conn`, then the result is ignored
  and `follow_fn` will simply return the original `conn`

  This gives a way to insert custom assertions, or other setup code without breaking
  the piped chain of functions.

  ### Parameters
    * `conn` A conn that has been set up to work in the test environment.
      Could be the conn originally passed in to the test;
    * `func` a function in the form of `fn(conn) -> end`;
    * `opts` A map of additional options
      * `:max_redirects` - Maximum number of redirects to follow. Defaults to `5`;

  ### Example:
      follow_fn( conn, fn(c) ->
          "/some_path/" <> token = c.request_path
          assert token == "valid_token"
        end)
  """
  def follow_fn(conn, func, opts \\ %{})

  def follow_fn(conn, func, opts) when is_list(opts),
    do: follow_fn(conn, func, Enum.into(opts, %{}))

  def follow_fn(conn, func, opts) do
    opts = Map.merge(%{max_redirects: 5}, opts)

    case func.(conn) do
      c = %Plug.Conn{} ->
        follow_redirect(c, opts.max_redirects)

      _ ->
        conn
    end
  end

  # ============================================================================
  # ============================================================================
  # private below

  if Mix.env() == :test do
    def test_find_html_link(html, identifier, method) do
      find_html_link(html, identifier, method)
    end

    def test_find_html_form(html, identifier, method, form_finder) do
      find_html_form(html, identifier, method, form_finder)
    end

    def test_build_form_data(form, fields) do
      build_form_data(form, fields)
    end
  end

  # ----------------------------------------------------------------------------
  defp request_path(conn, path, method, data \\ %{}) do
    case to_string(method) do
      "get" ->
        get(conn, path, data)

      "post" ->
        post(conn, path, data)

      "put" ->
        put(conn, path, data)

      "patch" ->
        patch(conn, path, data)

      "delete" ->
        delete(conn, path, data)
    end
  end

  # ----------------------------------------------------------------------------
  # don't really care if there are multiple copies of the same link,
  # just that it is actually on the page
  defp find_html_link(html, identifier, :get), do: find_html_link(html, identifier, "get")

  defp find_html_link(html, identifier, "get") do
    identifier = String.trim(identifier)

    # Newer versions of Floki require parse_document to be explicitly called before use
    {:ok, parsed_html} = Floki.parse_document(html)

    # scan all links, return the first where either the path or the content
    # is equal to the identifier
    Floki.find(parsed_html, "a")
    |> Enum.find_value(fn link ->
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
            Floki.text(link) =~ identifier ->
              link

            Floki.FlatText.get(kids) =~ identifier ->
              link

            # all other cases fail
            true ->
              nil
          end
      end
    end)
    |> case do
      nil ->
        {err_type, err_ident} =
          case identifier do
            "#" <> id -> {"id=", id}
            "/" <> _ -> {"href=", identifier}
            "http" <> _ -> {"href=", identifier}
            _ -> {"text containing ", identifier}
          end

        msg =
          "Failed to find link \"#{identifier}\", :get in the response\n" <>
            "Expected to find an anchor with #{err_type}\"#{err_ident}\""

        raise msg

      link ->
        [path] = Floki.attribute(link, "href")
        {:ok, path}
    end
  end

  defp find_html_link(html, identifier, method) do
    identifier = String.trim(identifier)

    # Newer versions of Floki require parse_document to be explicitly called before use
    {:ok, parsed_html} = Floki.parse_document(html)

    # scan all links, return the first where either the path or the content
    # is equal to the identifier
    Floki.find(parsed_html, "a")
    |> Enum.find_value(fn link ->
      {"a", _attribs, kids} = link

      case identifier do
        "#" <> id ->
          case Floki.attribute(link, "id") do
            [^id] -> link
            _ -> nil
          end

        "/" <> _ ->
          case Floki.attribute(link, "data-to") do
            [^identifier] -> link
            _ -> nil
          end

        "http" <> _ ->
          case Floki.attribute(link, "data-to") do
            [^identifier] -> link
            _ -> nil
          end

        _ ->
          cond do
            # see if the identifier is in the links's text
            Floki.text(link) =~ identifier ->
              link

            Floki.FlatText.get(kids) =~ identifier ->
              link

            # all other cases fail
            true ->
              nil
          end
      end
    end)
    |> case do
      nil ->
        {err_type, err_ident} =
          case identifier do
            "#" <> id -> {"id=", id}
            "/" <> _ -> {"href=", identifier}
            "http" <> _ -> {"href=", identifier}
            _ -> {"text containing ", identifier}
          end

        msg =
          "Failed to find link \"#{identifier}\", :#{method} in the response\n" <>
            "Expected to find an anchor with #{err_type}\"#{err_ident}\""

        raise msg

      link ->
        path =
          case Floki.attribute(link, "data-to") do
            [] ->
              msg =
                "Failed to find link \"#{identifier}\", :#{method} in the response\n" <>
                  "#{IO.ANSI.yellow()}Did you ask for the right method?" <>
                  IO.ANSI.default_color()

              raise msg

            [path] ->
              path
          end

        {:ok, path}
    end
  end

  # ----------------------------------------------------------------------------
  # don't really care if there are multiple copies of the same button,
  # just that it is actually on the page
  defp find_html_button(html, identifier, :get), do: find_html_button(html, identifier, "get")

  defp find_html_button(html, identifier, method) do
    identifier = String.trim(identifier)

    # Newer versions of Floki require parse_document to be explicitly called before use
    {:ok, parsed_html} = Floki.parse_document(html)

    # scan all links, return the first where either the path or the content
    # is equal to the identifier
    Floki.find(parsed_html, "button")
    |> Enum.find_value(fn button ->
      {"button", _attribs, kids} = button

      case identifier do
        "#" <> id ->
          case Floki.attribute(button, "id") do
            [^id] -> button
            _ -> nil
          end

        "/" <> _ ->
          case Floki.attribute(button, "data-to") do
            [^identifier] -> button
            _ -> nil
          end

        "http" <> _ ->
          case Floki.attribute(button, "data-to") do
            [^identifier] -> button
            _ -> nil
          end

        _ ->
          cond do
            # see if the identifier is in the links's text
            Floki.text(button) =~ identifier ->
              button

            Floki.FlatText.get(kids) =~ identifier ->
              button

            # all other cases fail
            true ->
              nil
          end
      end
    end)
    |> case do
      nil ->
        {err_type, err_ident} =
          case identifier do
            "#" <> id -> {"id=", id}
            "/" <> _ -> {"href=", identifier}
            "http" <> _ -> {"href=", identifier}
            _ -> {"text containing ", identifier}
          end

        msg =
          "Failed to find button \"#{identifier}\", #{inspect(method)} in the response\n" <>
            "Expected to find an button tag with #{err_type}\"#{err_ident}\""

        raise msg

      button ->
        [path] = Floki.attribute(button, "data-to")
        [method] = Floki.attribute(button, "data-method")
        {:ok, path, method}
    end
  end

  # ----------------------------------------------------------------------------

  # defp find_html_link_identifier() do
  # end

  # ----------------------------------------------------------------------------
  defp find_html_form(html, identifier, method, form_finder) do
    method =
      case method do
        nil -> nil
        other -> to_string(other)
      end

    # Newer versions of Floki require parse_document to be explicitly called before use
    {:ok, parsed_html} = Floki.parse_document(html)

    # scan all links, return the first where either the path or the content
    # is equal to the identifier
    Floki.find(parsed_html, form_finder)
    |> Enum.find_value(fn form ->
      {"form", _attribs, kids} = form

      case identifier do
        # if nil identifier, return the first form
        nil ->
          form

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
            Floki.text(form) =~ identifier ->
              form

            Floki.FlatText.get(kids) =~ identifier ->
              form

            # all other cases fail
            true ->
              nil
          end
      end
      |> verify_form_method(method)
    end)
    |> case do
      nil ->
        {err_type, err_ident} =
          case identifier do
            "#" <> id -> {"id=", id}
            "/" <> _ -> {"action=", identifier}
            "http" <> _ -> {"action=", identifier}
            _ -> {"text containing ", identifier}
          end

        msg =
          "Failed to find form \"#{identifier}\", :#{method} in the response\n" <>
            "Expected to find a form with #{err_type}\"#{err_ident}\""

        raise msg

      form ->
        [path] = Floki.attribute(form, "action")
        {:ok, path, form_method(form), form}
    end
  end

  # ========================================================
  # support for find

  # --------------------------------------------------------
  defp verify_form_method(false, _method), do: false
  defp verify_form_method(nil, _method), do: false
  # return form f no method requested
  defp verify_form_method(form, nil), do: form

  defp verify_form_method(form, method) do
    method = to_string(method)

    form_method(form)
    |> case do
      ^method -> form
      _ -> false
    end
  end

  # --------------------------------------------------------
  defp form_method(form) do
    # turns out get is right on the top level of the form
    case Floki.attribute(form, "method") do
      ["get"] ->
        "get"

      _ ->
        case Floki.find(form, "input[name=\"_method\"]") do
          [] ->
            "post"

          [found_input] ->
            [found_method] = Floki.attribute(found_input, "value")
            found_method
        end
    end
  end

  # ========================================================
  # support for building form data

  # ----------------------------------------------------------------------------
  defp build_form_data(form, user_tree) do
    tree = tree_with_emitted_warnings(form)
    case TreeEdit.apply_edits(tree, user_tree) do
      {:ok, edited} ->
        TreeFinish.to_action_params(edited)
      {:error, errors} ->
        Form.Messages.emit(errors, form)
        raise "Stopping"
    end
  end

  defp tree_with_emitted_warnings(form) do
    created = TreeCreation.build_tree(form)
    Form.Messages.emit(created.warnings, form)
    created.tree
  end
end
