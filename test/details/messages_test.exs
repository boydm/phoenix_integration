defmodule PhoenixIntegration.Details.MessagesTest do
  # As long as only this uses capture_io, async is safe
  use ExUnit.Case, async: true
  use Phoenix.ConnTest
  import ExUnit.CaptureIO
  alias PhoenixIntegration.Form.Messages

  @html """
    <form accept-charset="UTF-8" action="/form" method="post" id="proper_form">
      <input id="user_tag_name" name="user[tag][name]" type="text" value="tag">
    </form>
  """

  setup do 
    {:ok, _action, _method, form}  =   
      PhoenixIntegration.Requests.test_find_html_form(
        @html, "#proper_form", nil, "form")
    [form: form]
  end

  describe "warnings from the html form itself" do
  end

  describe "errors when applying test override values" do 

    test "build form raises setting missing field", %{form: form} do
      form_action = "/form"
      user_data = %{missing: "something"}
      
      fun = fn ->
        assert_raise(RuntimeError, build_form_fun(form, form_action, user_data))
      end
      
      assert_substrings(fun, 
        [ Messages.get(:no_such_name_in_form),
          "action:", "/form",
          "id:", "proper_form",
          "[:missing]", "something"
        ])
    end
  end

  def build_form_fun(form, form_action, user_data) do
    fn ->
      PhoenixIntegration.Requests.test_build_form_data__2(
        form, form_action, user_data)
    end
  end

  def assert_substrings(fun, substrings) do
    message = capture_io(:stderr, fun)
    Enum.map(substrings, fn substring -> 
      assert String.contains?(message, substring)
    end)
  end
end
