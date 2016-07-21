defmodule PhoenixIntegration.Html.FormsTest do
  use ExUnit.Case
  use Plug.Test
  import PhoenixIntegration.TestSupport.Requests

  import IEx

  @href_first_get   "/links/first"
  @href_second_get  "https://www.example.com/links/second"

  @form_action  "/form"
  @form_method  "put"
  @form_id      "#proper_form"

  #============================================================================
  # set up context 
  setup do
    %{html: get( conn(:get, "/"), "/test_html" ).resp_body}
  end


  #============================================================================
  # find form

  test "find form via uri or path", %{html: html} do
    found = PhoenixIntegration.Html.Forms.find( html, @form_action )
    {:ok, @form_action, @form_method, _form} = found
  end

  test "find form via id", %{html: html} do
    found = PhoenixIntegration.Html.Forms.find( html, @form_id )
    {:ok, @form_action, @form_method, _form} = found
  end

  test "find form via internal text", %{html: html} do
    found = PhoenixIntegration.Html.Forms.find( html, "Text in the proper form" )
    {:ok, @form_action, @form_method, _form} = found
  end

  test "find form raises on missing path", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "/invalid/path", :delete )
    end    
  end

  test "find form raises on invalid id", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "#other", :delete )
    end    
  end

  test "find form raises on missing text", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Html.Links.find( html, "Invalid Text", :delete )
    end    
  end

end