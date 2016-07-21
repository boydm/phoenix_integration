defmodule PhoenixIntegration.RequestTest do
  use ExUnit.Case
  use Plug.Test
  import PhoenixIntegration.TestSupport.Requests

  use PhoenixIntegration


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

  test "click_link :get dddd clicks a link in the conn's html", %{conn: conn} do
    get( conn, "/sample" )
    |> click_link( "#second" )
    |> assert_response( status: 200, path: "https://www.example.com/links/second" )
  end


end