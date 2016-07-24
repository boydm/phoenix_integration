defmodule PhoenixIntegration.TestEndpoint do
  use Plug.Test
#  import IEx

  @expected_json_data %{
    "one"   => 1,
    "two"   => "two",
    "other" => "Sample"
  }

  def init(opts) do
    opts
  end

  def call(conn, _opts) do
    respond( conn, conn.method, conn.request_path)
  end


  def respond( conn, "GET", "/test_json" ) do
    pre_get_json(conn, conn_request_path(conn))
    |> resp( 200, Poison.encode!(@expected_json_data) )
  end


  def respond( conn, "GET", "/test_redir" ) do
    Phoenix.ConnTest.build_conn(:get, conn_request_path(conn))
    |> Plug.Test.recycle_cookies( conn )
    |> put_resp_header("location", "/sample")
    |> put_status( 302 )
  end

  def respond( conn, "GET", "/circle_redir" ) do
    Phoenix.ConnTest.build_conn(:get, conn_request_path(conn))
    |> Plug.Test.recycle_cookies( conn )
    |> put_resp_header("location", conn_request_path(conn))
    |> put_status( 302 )
  end

  def respond( conn, "GET", "/sample" ) do
    pre_get_html(conn, conn_request_path(conn)) #  <> query
    |> resp( 200, File.read!("test/fixtures/templates/sample.html") )
  end

  def respond( conn, "GET", _path ) do
    pre_get_html(conn, conn_request_path(conn))
    |> resp( 200, File.read!("test/fixtures/templates/second.html") )
  end

  def respond( conn, "POST", _path ) do
    Phoenix.ConnTest.build_conn(:post, conn_request_path(conn))
    |> Plug.Test.recycle_cookies( conn )
    |> put_resp_header("location", "/second")
    |> put_status( 302 )
  end

  def respond( conn, "PUT", _path ) do
    Phoenix.ConnTest.build_conn(:put, conn_request_path(conn))
    |> Plug.Test.recycle_cookies( conn )
    |> put_resp_header("location", "/second")
    |> put_status( 302 )
  end

  def respond( conn, "PATCH", _path ) do
    Phoenix.ConnTest.build_conn(:patch, conn_request_path(conn))
    |> Plug.Test.recycle_cookies( conn )
    |> put_resp_header("location", "/second")
    |> put_status( 302 )
  end

  def respond( conn, "DELETE", _path ) do
    Phoenix.ConnTest.build_conn(:delete, conn_request_path(conn))
    |> Plug.Test.recycle_cookies( conn )
    |> put_resp_header("location", "/second")
    |> put_status( 302 )
  end


  #============================================================================
  defp pre_get_html(conn, path) do
    Phoenix.ConnTest.build_conn(:get, path)
    |> Plug.Test.recycle_cookies( conn )
    |> put_resp_content_type("text/html")
  end

  defp pre_get_json(conn, path) do
    Phoenix.ConnTest.build_conn(:get, path)
    |> Plug.Test.recycle_cookies( conn )
    |> put_resp_content_type("application/json")
  end

  defp conn_request_path(conn) do
    conn.request_path <> 
    case conn.query_string do
      nil -> ""
      "" -> ""
      query -> "?" <> query
    end
  end

end