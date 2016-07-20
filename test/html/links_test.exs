defmodule PhoenixIntegration.Html.LinksTest do
  use ExUnit.Case

  import IEx

  @href_first_get   "/links/first"
  @href_second_get  "https://www.example.com/links/second"

  @html "<h2>Sample Page</h2>\
  <a href=\"#{@href_first_get}\">First Link</a>\
  <a id=\"second\" href=\"#{@href_second_get}\">Second Link</a>
  <p id=\"other\">text_here</p>"



  #============================================================================
  # get links

  test "find :get anchor in html via uri or path" do
    assert PhoenixIntegration.Html.Links.find( @html, @href_first_get ) == {:ok, @href_first_get}
    assert PhoenixIntegration.Html.Links.find( @html, @href_first_get, :get ) == {:ok, @href_first_get}
    assert PhoenixIntegration.Html.Links.find( @html, @href_second_get ) == {:ok, @href_second_get}
  end

  test "find :get anchor in html via #id" do
    assert PhoenixIntegration.Html.Links.find( @html, "#second" ) == {:ok, @href_second_get}
  end

  test "find :get anchor in html via text" do
    assert PhoenixIntegration.Html.Links.find( @html, "First Link" ) ==  {:ok, @href_first_get}
    assert PhoenixIntegration.Html.Links.find( @html, "Second Link" ) == {:ok, @href_second_get}
  end

  test "find :get raises on invalid id" do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( @html, "#other" )
    end    
  end

  test "find :get raises on missing text" do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( @html, "Invalid Text" )
    end    
  end

  test "find :get raises on missing path" do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( @html, "/invalid/path" )
    end    
  end

  #============================================================================
  # post links

  test "find :post anchor in html via uri or path" do
    assert PhoenixIntegration.Html.Links.find( @html, @href_first_get, :post ) == {:ok, @href_first_get}
    assert PhoenixIntegration.Html.Links.find( @html, @href_second_get, :post ) == {:ok, @href_second_get}
  end

  #============================================================================
  # put links

  #============================================================================
  # patch links

  #============================================================================
  # delete links

end