defmodule PhoenixIntegration.Html.LinksTest do
  use ExUnit.Case

  import IEx

  @href_first   "/links/first"
  @href_second  "https://www.example.com/links/second"

  @html "<h2>Sample Page</h2>\
  <a href=\"#{@href_first}\">First Link</a>\
  <a id=\"second\" href=\"#{@href_second}\">Second Link</a>
  <p id=\"other\">text_here</p>"



  #============================================================================
  # get links

  test "find :get anchor in html via uri or path" do
    assert PhoenixIntegration.Html.Links.find( @html, @href_first ) == {:ok, @href_first}
    assert PhoenixIntegration.Html.Links.find( @html, @href_second ) == {:ok, @href_second}
  end

  test "find :get anchor in html via #id" do
    assert PhoenixIntegration.Html.Links.find( @html, "#second" ) == {:ok, @href_second}
  end

  test "find :get anchor in html via text" do
    assert PhoenixIntegration.Html.Links.find( @html, "First Link" ) ==  {:ok, @href_first}
    assert PhoenixIntegration.Html.Links.find( @html, "Second Link" ) == {:ok, @href_second}
  end

  test "find :get raises on invalid id" do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( @html, "#other" )
    end    
  end

  #============================================================================
  # post links


  #============================================================================
  # put links

  #============================================================================
  # patch links

  #============================================================================
  # delete links

end