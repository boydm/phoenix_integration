defmodule PhoenixIntegration.Html.LinksTest do
  use ExUnit.Case, async: true
  use Plug.Test
  import PhoenixIntegration.TestSupport.Requests

  @href_first_get   "/links/first"
  @href_second_get  "https://www.example.com/links/second"

  @href_post    "/links/post"
  @href_put     "/links/put"
  @href_patch   "/links/patch"
  @href_delete  "/links/delete"

  #============================================================================
  # set up context 
  setup do
    %{conn: conn(:get, "/")}
  end


  #============================================================================
  # get links

  test "find :get anchor in html via uri or path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, @href_first_get ) == {:ok, @href_first_get}
    assert PhoenixIntegration.Html.Links.find( html, @href_first_get, :get ) == {:ok, @href_first_get}
    assert PhoenixIntegration.Html.Links.find( html, @href_second_get ) == {:ok, @href_second_get}
  end

  test "find :get anchor in html via #id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "#second" ) == {:ok, @href_second_get}
  end

  test "find :get anchor in html via text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "First Link" ) ==  {:ok, @href_first_get}
    assert PhoenixIntegration.Html.Links.find( html, "Second Link" ) == {:ok, @href_second_get}
  end

  test "find :get raises on invalid id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "#other" )
    end    
  end

  test "find :get raises on missing text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "Invalid Text" )
    end    
  end

  test "find :get raises on missing path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "/invalid/path" )
    end    
  end

  #============================================================================
  # post links

  test "find :post anchor in html via uri or path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, @href_post, :post ) == {:ok, @href_post}
  end

  test "find :post anchor in html via #id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "#post_id", :post ) == {:ok, @href_post}
  end

  test "find :post anchor in html via text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "POST link text", :post ) ==  {:ok, @href_post}
  end

  test "find :post raises on invalid id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "#other", :post )
    end    
  end

  test "find :post raises on missing text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "Invalid Text", :post )
    end    
  end

  test "find :post raises on missing path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "/invalid/path", :post )
    end    
  end


  #============================================================================
  # put links

  test "find :put anchor in html via uri or path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, @href_put, :put ) == {:ok, @href_put}
  end

  test "find :put anchor in html via #id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "#put_id", :put ) == {:ok, @href_put}
  end

  test "find :put anchor in html via text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "PUT link text", :put ) ==  {:ok, @href_put}
  end

  test "find :put raises on invalid id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "#other", :put )
    end    
  end

  test "find :put raises on missing text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "Invalid Text", :put )
    end    
  end

  test "find :put raises on missing path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "/invalid/path", :put )
    end    
  end

  #============================================================================
  # patch links

  test "find :patch anchor in html via uri or path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, @href_patch, :patch ) == {:ok, @href_patch}
  end

  test "find :patch anchor in html via #id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "#patch_id", :patch ) == {:ok, @href_patch}
  end

  test "find :patch anchor in html via text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "PATCH link text", :patch ) ==  {:ok, @href_patch}
  end

  test "find :patch raises on invalid id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "#other", :patch )
    end    
  end

  test "find :patch raises on missing text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "Invalid Text", :patch )
    end    
  end

  test "find :patch raises on missing path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "/invalid/path", :patch )
    end    
  end

  #============================================================================
  # delete links
  test "find :delete anchor in html via uri or path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, @href_delete, :delete ) == {:ok, @href_delete}
  end

  test "find :delete anchor in html via #id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "#delete_id", :delete ) == {:ok, @href_delete}
  end

  test "find :delete anchor in html via text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert PhoenixIntegration.Html.Links.find( html, "DELETE link text", :delete ) ==  {:ok, @href_delete}
  end

  test "find :delete raises on invalid id", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "#other", :delete )
    end    
  end

  test "find :delete raises on missing text", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "Invalid Text", :delete )
    end    
  end

  test "find :delete raises on missing path", %{conn: conn} do
    html = get( conn, "/test_html" ).resp_body
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "/invalid/path", :delete )
    end    
  end

end