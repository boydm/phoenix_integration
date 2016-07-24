defmodule PhoenixIntegration.LinksTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest
  @endpoint PhoenixIntegration.TestEndpoint

  @href_first_get   "/links/first"
  @href_second_get  "https://www.example.com/links/second"

  @href_post    "/links/post"
  @href_put     "/links/put"
  @href_patch   "/links/patch"
  @href_delete  "/links/delete"

  #============================================================================
  # set up context 
  setup do
    %{html: get( build_conn(:get, "/"), "/sample" ).resp_body}
  end

  #============================================================================
  # get links

  test "find :get anchor in html via uri or path", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, @href_first_get, :get ) == {:ok, @href_first_get}
    assert PhoenixIntegration.Requests.test_find_html_link( html, @href_first_get, :get ) == {:ok, @href_first_get}
    assert PhoenixIntegration.Requests.test_find_html_link( html, @href_second_get, :get ) == {:ok, @href_second_get}
  end

  test "find :get anchor in html via #id", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "#second", :get ) == {:ok, @href_second_get}
  end

  test "find :get anchor in html via text", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "First Link", :get ) ==  {:ok, @href_first_get}
    assert PhoenixIntegration.Requests.test_find_html_link( html, "Second Link", :get ) == {:ok, @href_second_get}
  end

  test "find :get raises on invalid id", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "#other", :get )
    end    
  end

  test "find :get raises on missing text", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "Invalid Text", :get )
    end    
  end

  test "find :get raises on missing path", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "/invalid/path", :get )
    end    
  end

  #============================================================================
  # post links

  test "find :post anchor in html via uri or path", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, @href_post, :post ) == {:ok, @href_post}
  end

  test "find :post anchor in html via #id", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "#post_id", :post ) == {:ok, @href_post}
  end

  test "find :post anchor in html via text", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "POST link text", :post ) ==  {:ok, @href_post}
  end

  test "find :post raises on invalid id", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "#other", :post )
    end    
  end

  test "find :post raises on missing text", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "Invalid Text", :post )
    end    
  end

  test "find :post raises on missing path", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "/invalid/path", :post )
    end    
  end


  #============================================================================
  # put links

  test "find :put anchor in html via uri or path", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, @href_put, :put ) == {:ok, @href_put}
  end

  test "find :put anchor in html via #id", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "#put_id", :put ) == {:ok, @href_put}
  end

  test "find :put anchor in html via text", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "PUT link text", :put ) ==  {:ok, @href_put}
  end

  test "find :put raises on invalid id", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "#other", :put )
    end    
  end

  test "find :put raises on missing text", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "Invalid Text", :put )
    end    
  end

  test "find :put raises on missing path", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "/invalid/path", :put )
    end    
  end

  #============================================================================
  # patch links

  test "find :patch anchor in html via uri or path", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, @href_patch, :patch ) == {:ok, @href_patch}
  end

  test "find :patch anchor in html via #id", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "#patch_id", :patch ) == {:ok, @href_patch}
  end

  test "find :patch anchor in html via text", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "PATCH link text", :patch ) ==  {:ok, @href_patch}
  end

  test "find :patch raises on invalid id", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "#other", :patch )
    end    
  end

  test "find :patch raises on missing text", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "Invalid Text", :patch )
    end    
  end

  test "find :patch raises on missing path", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "/invalid/path", :patch )
    end    
  end

  #============================================================================
  # delete links
  test "find :delete anchor in html via uri or path", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, @href_delete, :delete ) == {:ok, @href_delete}
  end

  test "find :delete anchor in html via #id", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "#delete_id", :delete ) == {:ok, @href_delete}
  end

  test "find :delete anchor in html via text", %{html: html} do
    assert PhoenixIntegration.Requests.test_find_html_link( html, "DELETE link text", :delete ) ==  {:ok, @href_delete}
  end

  test "find :delete raises on invalid id", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "#other", :delete )
    end    
  end

  test "find :delete raises on missing text", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "Invalid Text", :delete )
    end    
  end

  test "find :delete raises on missing path", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_link( html, "/invalid/path", :delete )
    end    
  end

end