defmodule PhoenixIntegration.RequestTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import PhoenixIntegration.TestSupport.Requests

  use PhoenixIntegration

#  import IEx


  #============================================================================
  # set up context 
  setup do
    %{conn: conn(:get, "/")}
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
    |> click_link( "#post_id", :post )
    |> assert_response( status: 302, to: "/second" )
  end

  test "click_link :put clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "#put_id", :put )
    |> assert_response( status: 302, to: "/second" )
  end

  test "click_link :patch clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "#patch_id", :patch )
    |> assert_response( status: 302, to: "/second" )
  end

  test "click_link :delete clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "#delete_id", :delete )
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
    |> follow_link( "#post_id", :post )
    |> assert_response( status: 200, path: "/second" )
  end

  test "follow_link :put clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_link( "#put_id", :put )
    |> assert_response( status: 200, path: "/second" )
  end

  test "follow_link :patch clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_link( "#patch_id", :patch )
    |> assert_response( status: 200, path: "/second" )
  end

  test "follow_link :delete clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_link( "#delete_id", :delete )
    |> assert_response( status: 200, path: "/second" )
  end

  #============================================================================
  # submit_form

  test "submit_form works", %{conn: conn} do
    get( conn, "/sample" )
    |> submit_form( "#proper_form", %{user: %{name: "Fine Name"}} )
    |> assert_response( status: 302, to: "/second" )
  end

  #============================================================================
  # follow_form

  test "follow_form works", %{conn: conn} do
    get( conn, "/sample" )
    |> follow_form( "#proper_form", %{user: %{name: "Fine Name"}} )
    |> assert_response( status: 200, path: "/second" )
  end



end








