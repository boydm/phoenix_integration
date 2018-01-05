defmodule PhoenixIntegration.RequestTest do
  use ExUnit.Case
  use Phoenix.ConnTest, async: true
  @endpoint PhoenixIntegration.TestEndpoint
  
  use PhoenixIntegration

  import IEx

  #============================================================================
  # set up context 
  setup do
    %{conn: build_conn(:get, "/")}
  end

  #============================================================================
  # follow_redirect

  test "follow_redirect should get the location redirected to in the conn", %{conn: conn} do
    get( conn, "/test_redir" )
    |> assert_response( status: 302 )
    |> follow_redirect()
    |> assert_response( status: 200, path: "/sample" )
  end

  test "follow_redirect raises if there are too many redirects", %{conn: conn} do
    conn = get( conn, "/circle_redir" )
    assert_raise RuntimeError, fn ->
      follow_redirect( conn )
    end    
  end

  #============================================================================
  # follow_path

  test "follow_path gets and redirects all in one", %{conn: conn} do
    follow_path(conn, "/test_redir")
    |> assert_response( status: 200, path: "/sample" )
  end

  #============================================================================
  # click_link

  test "click_link :get clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "First Link" )
    |> assert_response( status: 200, path: "/links/first" )
    |> click_link( "#return" )
    |> assert_response( status: 200, path: "/sample" )
  end

  test "click_link :post clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "#post_id", method: :post )
    |> assert_response( status: 302, to: "/second" )
  end

  test "click_link :put clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "#put_id", method: :put )
    |> assert_response( status: 302, to: "/second" )
  end

  test "click_link :patch clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "#patch_id", method: :patch )
    |> assert_response( status: 302, to: "/second" )
  end

  test "click_link :delete clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "#delete_id", method: :delete )
    |> assert_response( status: 302, to: "/second" )
  end

  #============================================================================
  # follow_link

  test "follow_link :get clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_link( "First Link" )
    |> assert_response( status: 200, path: "/links/first" )
    |> follow_link( "#return" )
    |> assert_response( status: 200, path: "/sample" )
  end

  test "follow_link :post clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_link( "#post_id", method: :post )
    |> assert_response( status: 200, path: "/second" )
  end

  test "follow_link :put clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_link( "#put_id", method: :put )
    |> assert_response( status: 200, path: "/second" )
  end

  test "follow_link :patch clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_link( "#patch_id", method: :patch )
    |> assert_response( status: 200, path: "/second" )
  end

  test "follow_link :delete clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_link( "#delete_id", method: :delete )
    |> assert_response( status: 200, path: "/second" )
  end

  #============================================================================
  # submit_form

  test "submit_form works", %{conn: conn} do
    get( conn, "/sample" )
    |> submit_form( %{user: %{name: "Fine Name"}}, %{identifier: "#proper_form"} )
    |> assert_response( status: 302, to: "/second" )
  end

  #============================================================================
  # follow_form

  test "follow_form works", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_form( %{user: %{name: "Fine Name"}}, %{identifier: "#proper_form"} )
    |> assert_response( status: 200, path: "/second" )
  end

  test "follow_form works on upload", %{conn: conn} do
    upload = %Plug.Upload{content_type: "text", path: "mix.exs", filename: "mix.exs"}
    
    get( conn, "/sample" )
    |> follow_form( %{user: %{photo: upload}}, %{identifier: "#upload_form"} )
    |> assert_response( status: 200, path: "/second" )
  end

  test "follow_form works on dates", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_form( %{user: %{joined_at: %DateTime{year: 2017, month: 02, day: 05, zone_abbr: "UTC", hour: 12, minute: 0, second: 0, time_zone: "UTC", utc_offset: 0, std_offset: 0}}}, %{identifier: "#proper_form"} )
    |> assert_response( status: 200, path: "/second" )
  end

  #============================================================================
  # fetch_form
  test "fetch_form works", %{conn: conn} do
    form = get( conn, "/sample" )
    |> fetch_form( %{identifier: "#proper_form"} )

    %{
      action: "/form",
      id: "proper_form",
      inputs: %{
        _csrf_token: csrf_token,
        _method: "put",
        _utf8: "✓",
        user: %{
          joined_at: %{day: nil, hour: nil, minute: nil, month: nil, year: nil},
          name: "Initial Name",
          species: "human",
          story: "Initial user story",
          tag: %{name: "tag"},
          type: "type_two"}
        },
      method: "put"
    } = form

    assert is_bitstring(csrf_token)
  end


  #============================================================================
  # follow_fn

  test "follow_form returns fn's conn", %{conn: conn} do
    refute conn.assigns[:test]
    conn = follow_fn( conn, fn(c) -> Plug.Conn.assign(c, :test, "response") end)
    assert conn.assigns[:test] == "response"
  end

  test "follow_form ignores non conn responses", %{conn: conn} do
    assert follow_fn( conn, fn(_) -> "some string" end) == conn
  end

  test "follow_fn follows redirects in the returned conn", %{conn: conn} do
    follow_fn( conn, fn(c) -> get(c, "/test_redir") end)
    |> assert_response( status: 200, path: "/sample" )
  end

end
