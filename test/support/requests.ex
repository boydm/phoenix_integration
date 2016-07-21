defmodule PhoenixIntegration.TestSupport.Requests do
  use Plug.Test
  
  @expected_json_data %{
    "one"   => 1,
    "two"   => "two",
    "other" => "Sample"
  }


  #============================================================================
  # faked up request/conn functions
  def get(conn, path, data \\ %{})

  def get(old_conn, "/test_json" <> query, _data) do
    pre_get_json(old_conn, "/test_json" <> query)
    |> resp( 200, Poison.encode!(@expected_json_data) )
  end

  def get(old_conn, "/test_redir" <> query, _data) do
    conn(:get, "/test_redir" <> query)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_header("location", "/sample")
    |> put_status( 302 )
  end

  def get(old_conn, "/circle_redir" <> query, _data) do
    conn(:get, "/circle_redir" <> query)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_header("location", "/circle_redir")
    |> put_status( 302 )
  end

  def get(old_conn, "/sample" <> query, _data) do
    pre_get_html(old_conn, "/sample" <> query)
    |> resp( 200, File.read!("test/fixtures/templates/sample.html") )
  end

  def get(old_conn, path, _data) do
    pre_get_html(old_conn, path)
    |> resp( 200, File.read!("test/fixtures/templates/second.html") )
  end

  def post(old_conn, path, _data \\ %{} ) do
    conn(:post, path)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_header("location", "/second")
    |> put_status( 302 )
  end

  def put(old_conn, path, _data \\ %{} ) do
    conn(:put, path)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_header("location", "/second")
    |> put_status( 302 )
  end

  def patch(old_conn, path, _data \\ %{} ) do
    conn(:patch, path)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_header("location", "/second")
    |> put_status( 302 )
  end

  def delete(old_conn, path, _data \\ %{} ) do
    conn(:delete, path)
    |> Plug.Test.recycle_cookies( old_conn )
    |> put_resp_header("location", "/second")
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