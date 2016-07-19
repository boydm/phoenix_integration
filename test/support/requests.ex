defmodule PhoenixIntegration.TestSupport.Requests do
  use Plug.Test

  @expected_json_data %{
    "one"   => 1,
    "two"   => "two",
    "other" => "Sample"
  }

  #============================================================================
  # faked up request/conn functions

  def get(old_conn, "/test_html" <> query) do
    pre_get_html(old_conn, "/test_html" <> query)
    |> resp( 200, "Sample Page body goes here" )
  end

  def get(old_conn, "/test_json" <> query) do
    pre_get_json(old_conn, "/test_json" <> query)
    |> resp( 200, Poison.encode!(@expected_json_data) )
  end

  def get(old_conn, "/test_redir" <> query) do
    conn(:get, "/test_redir" <> query)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_header("location", "/test_html")
    |> put_status( 302 )
  end




  #============================================================================
  defp pre_get_html(old_conn, path) do
    conn(:get, path)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_content_type("text/html")
  end

  defp pre_get_json(old_conn, path) do
    conn(:get, path)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_content_type("application/json")
  end

end