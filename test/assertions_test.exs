defmodule PhoenixIntegration.AssertionsTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest
  @endpoint PhoenixIntegration.TestEndpoint

#  import IEx

  #============================================================================
  # set up context 
  setup do
    %{conn: build_conn(:get, "/")}
  end

  #============================================================================
  # known data

  @expected_json_data %{
    "one"   => 1,
    "two"   => "two",
    "other" => "Sample"
  }
  @invalid_json_data %{
    "one"   => 1,
    "two"   => 2,
    "other" => "Sample"
  }

  #============================================================================
  # assert_response - dives into the conn returned from a get/put/post/delete
  # call and asserts the given content.

  #----------------------------------------------------------------------------
  # assert status
  test "assert_response :status succeeds", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.assert_response(conn, status: 200 )
  end
  test "assert_response :status fails if wrong status", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, status: 201 )
    end    
  end

  #----------------------------------------------------------------------------
  # assert  uri / path
  test "assert_response :uri succeeds", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.assert_response(conn, uri: "/sample" )
    PhoenixIntegration.Assertions.assert_response(conn, path: "/sample" )
  end
  test "assert_response :uri ignores the scheme/host and such", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.assert_response(conn, uri: "http://www.example.com/sample" )
  end
  test "assert_response :path is works independent of query order", %{conn: conn} do
    conn = get conn, "/sample?a=1&b=2"
    PhoenixIntegration.Assertions.assert_response(conn, uri: "/sample?a=1&b=2" )
    PhoenixIntegration.Assertions.assert_response(conn, uri: "/sample?b=2&a=1" )
    PhoenixIntegration.Assertions.assert_response(conn, path: "/sample?a=1&b=2" )
    PhoenixIntegration.Assertions.assert_response(conn, path: "/sample?b=2&a=1" )
  end
  test "assert_response :path fails if wrong root path", %{conn: conn} do
    conn = get conn, "/sample?a=1&b=2"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, uri: "/other?a=1&b=2"  )
    end    
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, path: "/other?a=1&b=2"  )
    end    
  end
  test "assert_response :path fails if wrong query params", %{conn: conn} do
    conn = get conn, "/sample?a=1&b=2"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, uri: "/sample?a=2&b=2"  )
    end    
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, path: "/sample?a=2&b=2"  )
    end    
  end
  test "assert_response :path fails if missing query params", %{conn: conn} do
    conn = get conn, "/sample?a=1&b=2"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, uri: "/sample?a=1&b=2&missing=2"  )
    end    
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, path: "/sample?a=1&b=2&missing=2"  )
    end    
  end

  #----------------------------------------------------------------------------
  # assert body
  test "assert_response :body succeeds", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.assert_response(conn, body: "Sample Page" )
  end
  test "assert_response :body succeeds mith multiple", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.assert_response(conn,
      body: "Sample",
      body: "Page"
    )
  end
  test "assert_response :body fails if string not present", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, body: "Invalid" )
    end    
  end
  test "assert_response :body multiple fails if any not present", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
    PhoenixIntegration.Assertions.assert_response(conn,
      body: "Sample Page",
      body: "Invalid"
    )
    end    
  end

  #----------------------------------------------------------------------------
  # assert content_type
  test "assert_response :content_type succeeds", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.assert_response(conn, content_type: "text/html" )
    PhoenixIntegration.Assertions.assert_response(conn, content_type: "html" )
  end
  test "assert_response :content_type fails if wrong type", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, content_type: "json" )
    end    
  end

  #----------------------------------------------------------------------------
  # assert html
  test "assert_response :html succeeds", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.assert_response(conn,
      body: "Sample",
      body: "Page"
      )
  end
  test "assert_response :html fails if wrong type", %{conn: conn} do
    conn = get conn, "/test_json"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, html: "Sample Page" )
    end    
  end
  test "assert_response :html fails if missing content", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, html: "invalid content" )
    end    
  end

  #----------------------------------------------------------------------------
  # assert json
  test "assert_response :json succeeds", %{conn: conn} do
    conn = get conn, "/test_json"
    PhoenixIntegration.Assertions.assert_response( conn, json: @expected_json_data )
  end
  test "assert_response :json fails if wrong type", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, json: "Sample" )
    end    
  end
  test "assert_response :json fails if content wrong", %{conn: conn} do
    conn = get conn, "/test_json"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response( conn, json: @invalid_json_data )
    end    
  end

  #----------------------------------------------------------------------------
  # assert redirect / to
  test "assert_response :redirect succeeds", %{conn: conn} do
    conn = get conn, "/test_redir"
    PhoenixIntegration.Assertions.assert_response(conn, redirect: "/sample" )
    PhoenixIntegration.Assertions.assert_response(conn, to: "/sample" )
  end
  test "assert_response :redirect fails if redirects to wrong path", %{conn: conn} do
    conn = get conn, "/test_redir"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, redirect: "/other/path" )
    end    
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.assert_response(conn, to: "/other/path" )
    end    
  end

  #============================================================================
  # refute_response - dives into the conn returned from a get/put/post/delete
  # call and refutes the given content.

  #----------------------------------------------------------------------------
  # refute body
  test "refute_response :body succeeds", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.refute_response(conn, body: "not_in_body" )
  end
  test "refute_response :body succeeds mith multiple", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.refute_response(conn,
      body: "not_in_body",
      body: "this_isnt_either"
    )
  end
  test "refute_response :body fails if string IS present", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, body: "Sample Page" )
    end    
  end
  test "refute_response :body multiple fails if any is present", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
    PhoenixIntegration.Assertions.refute_response(conn,
      body: "not_in_body",
      body: "Sample Page"
    )
    end    
  end

  #----------------------------------------------------------------------------
  # refute content_type
  test "refute_response :content_type succeeds", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.refute_response(conn, content_type: "json" )
  end
  test "refute_response :content_type fails if is the type", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, content_type: "html" )
    end    
  end

  #----------------------------------------------------------------------------
  # refute status
  test "refute_response :status succeeds", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.refute_response(conn, status: 201 )
  end
  test "refute_response :status fails if is the status", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, status: 200 )
    end    
  end

  #----------------------------------------------------------------------------
  # refute html
  test "refute_response :html succeeds with wrong content", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.refute_response(conn, body: "not_in_body" )
  end
  test "refute_response :html succeeds if wrong type", %{conn: conn} do
    conn = get conn, "/test_json"
    PhoenixIntegration.Assertions.refute_response(conn, html: "Sample" )
  end
  test "refute_response :html fails if contains content", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, html: "Sample Page" )
    end    
  end

  #----------------------------------------------------------------------------
  # refute json
  test "refute_response :json succeeds", %{conn: conn} do
    conn = get conn, "/test_json"
    PhoenixIntegration.Assertions.refute_response( conn, json: @invalid_json_data )
  end
  test "refute_response :json succeeds if wrong type", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.refute_response(conn, json: "Sample" )
  end
  test "refute_response :json fails if content found", %{conn: conn} do
    conn = get conn, "/test_json"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response( conn, json: @expected_json_data )
    end    
  end


  #----------------------------------------------------------------------------
  # refute uri / path
  test "refute_response :uri succeeds with wrong path", %{conn: conn} do
    conn = get conn, "/sample?a=1&b=2"
    PhoenixIntegration.Assertions.refute_response(conn, uri: "/sample/invalid?a=1&b=2" )
    PhoenixIntegration.Assertions.refute_response(conn, path: "/sample/invalid?a=1&b=2" )
  end
  test "refute_response :uri succeeds with wrong query", %{conn: conn} do
    conn = get conn, "/sample?a=1&b=2"
    PhoenixIntegration.Assertions.refute_response(conn, uri: "/sample?a=2&b=2" )
    PhoenixIntegration.Assertions.refute_response(conn, path: "/sample?a=2&b=2" )
  end
  test "refute_response :uri succeeds with missing query item", %{conn: conn} do
    conn = get conn, "/sample?a=1&b=2"
    PhoenixIntegration.Assertions.refute_response(conn, uri: "/sample?a=1&b=2&c=3" )
    PhoenixIntegration.Assertions.refute_response(conn, path: "/sample?a=2&b=2&c=3" )
  end
  test "refute_response :uri throws if found regardless of query order", %{conn: conn} do
    conn = get conn, "/sample?a=1&b=2"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, uri: "/sample?a=1&b=2"  )
    end    
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, uri: "/sample?b=2&a=1"  )
    end    
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, path: "/sample?a=1&b=2"  )
    end
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, path: "/sample?b=2&a=1"  )
    end
  end
  test "refute_response :uri ignores the scheme/host and such", %{conn: conn} do
    conn = get conn, "/sample"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, uri: "http://www.example.com/sample"  )
    end    
  end


  #----------------------------------------------------------------------------
  # refute redirect / to
  test "refute_response :redirect succeeds if not redirecting", %{conn: conn} do
    conn = get conn, "/sample"
    PhoenixIntegration.Assertions.refute_response(conn, redirect: "/sample" )
    PhoenixIntegration.Assertions.refute_response(conn, to: "/sample" )
  end
  test "refute_response :redirect succeeds if redirecting to the wrong place", %{conn: conn} do
    conn = get conn, "/test_redir"
    PhoenixIntegration.Assertions.refute_response(conn, redirect: "/sample/invalid" )
    PhoenixIntegration.Assertions.refute_response(conn, to: "/sample/invalid" )
  end
  test "refute_response :redirect fails if redirects to given path", %{conn: conn} do
    conn = get conn, "/test_redir"
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, redirect: "/sample" )
    end    
    assert_raise PhoenixIntegration.Assertions.ResponseError, fn ->
      PhoenixIntegration.Assertions.refute_response(conn, to: "/sample" )
    end    
  end

end






