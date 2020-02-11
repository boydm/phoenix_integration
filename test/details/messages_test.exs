defmodule PhoenixIntegration.Details.MessagesTest do
  use ExUnit.Case
  use Phoenix.ConnTest
  import ExUnit.CaptureIO
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.Messages

  describe "warnings from the html form itself" do
    test "a tag without a name" do
      html = ~S| <input type="radio"/> |
      form = form_for html

      assert_substrings(fn -> 
        build_form_fun(form, %{}).()
      end,
        [Messages.get(:tag_has_no_name),
         "It can't be included in the params sent to the controller",
         String.trim(html)
        ])
    end

    test "a nonsensical name" do
      html = ~S| <input name="" type="radio"/> |
      form = form_for html

      assert_substrings(fn -> 
        build_form_fun(form, %{}).()
      end,
        [Messages.get(:empty_name),
         String.trim(html)
        ])
    end
  end

  describe "errors when applying test override values" do 
    test "build form raises setting missing field" do
      form = form_for """
        <input id="user_tag_name" name="user[tag]" type="text" value="tag">
        """
      
      user_data = %{user: %{i_made_a_typo: "new value"}}

      fun = fn ->
        assert_raise(RuntimeError, build_form_fun(form, user_data))
      end
      
      assert_substrings(fun, 
        [ Messages.get(:no_such_name_in_form),
          "action:", "/form",
          "id:", "proper_form",
          "[:user, :i_made_a_typo]", "new value"
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

