defmodule PhoenixIntegration.Details.MessagesTest do
  use ExUnit.Case
  use Phoenix.ConnTest
  import ExUnit.CaptureIO
  alias PhoenixIntegration.Form.Messages

  def form_for(html_snippet) do
    html =
      """
      <form accept-charset="UTF-8" action="/form" method="post" id="proper_form">
        #{html_snippet}
      </form>
      """

    {:ok, _action, _method, form}  =   
      PhoenixIntegration.Requests.test_find_html_form(
        html, "#proper_form", nil, "form")
    form
  end

  describe "warnings from the html form itself" do
    test "a tag without a name" do
      form = form_for ~S| <input type="radio" checked> |

      assert_substrings(fn -> 
        build_form_fun(form, %{}).()
      end,
        ["has no name"]
      )
    end
  end

  describe "errors when applying test override values" do 
    test "build form raises setting missing field" do
      form = form_for """
        <input id="user_tag_name" name="user[tag][name]" type="text" value="tag">
        """
      
      user_data = %{missing: "something"}

      fun = fn ->
        assert_raise(RuntimeError, build_form_fun(form, user_data))
      end
      
      assert_substrings(fun, 
        [ Messages.get(:no_such_name_in_form),
          "action:", "/form",
          "id:", "proper_form",
          "[:missing]", "something"
        ])
    end
  end

  def build_form_fun(form, user_data) do
    fn ->
      PhoenixIntegration.Requests.test_build_form_data__2(form, user_data)
    end
  end

  def assert_substrings(fun, substrings) do
    message = capture_io(fun)
    # IO.puts "======"
    # IO.puts message # for visual inspection
    # IO.puts "======"
    
    Enum.map(substrings, fn substring -> 
      assert String.contains?(message, substring)
    end)
  end
end
p
