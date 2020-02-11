defmodule PhoenixIntegration.Details.MessagesTest do
  use ExUnit.Case
  use Phoenix.ConnTest
  import ExUnit.CaptureIO
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.Messages

  #########################################
  #
  # IMPORTANT
  #
  # Because assert_substrings traps IO, certain test failures won't
  # show any debugging output (from IO.inspect). To work on those,
  # extract the code that does the work out of the `assert_substrings`,
  # like this:
  #         build_form_fun(form, %{}).()   # TEMPORARY
  #
  #         assert_substrings(fn -> 
  #           build_form_fun(form, %{}).()
  #         ...




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

    test "a less-nested name follows a more deeply nexted name" do
      # Phoenix retains the earlier (more nested) value.
      html = """
        <input type="text" name="top_level[param][subparam]" value="y">
        <input type="text" name="top_level[param]"           value="x">
      """
      form = form_for html

      assert_substrings(fn -> 
        build_form_fun(form, %{}).()
      end,
        [Messages.get(:form_conflicting_paths),
         "top_level[param][subparam]",
         "top_level[param]"
        ])
    end
    
  end

  describe "errors when applying test override values" do 
    test "setting missing field (as a leaf)" do
      form = form_for """
        <input id="user_tag_name" name="user[tag]" type="text" value="tag">
        """
      
      user_data = %{user: %{i_made_a_typo: "new value"}}

      fun = fn ->
        assert_raise(RuntimeError, build_form_fun(form, user_data))
      end
      
      assert_substrings(fun, 
        [ Messages.get(:no_such_name_in_form),
          "Is this a typo?", ":i_made_a_typo",
          "action:", "/form",
          "id:", "proper_form",
          "[:user, :i_made_a_typo]", "new value"
        ])
    end

    test "setting missing field (wrong interior node)" do
      form = form_for """
        <input id="user_tag_name" name="user[tag]" type="text" value="tag">
        """
      
      user_data = %{i_made_a_typo: %{tag: "new value"}}

      fun = fn ->
        assert_raise(RuntimeError, build_form_fun(form, user_data))
      end
      
      assert_substrings(fun, 
        [ Messages.get(:no_such_name_in_form),
          "Is this a typo?", ":i_made_a_typo",
          "[:i_made_a_typo, :tag]", "new value"
        ])
    end

    test "setting a prefix of a field" do
      form = form_for """
        <input name="user[tag][name]" type="text" value="tag">
        """
      
      user_data = %{user: %{tag: "new value"}}

      fun = fn ->
        assert_raise(RuntimeError, build_form_fun(form, user_data))
      end
      
      assert_substrings(fun, 
        [ Messages.get(:no_such_name_in_form),
          "You provided only a prefix of all the available names.",
          "Here is your path", "[:user, :tag]",
          "Here is an available name", "user[tag][name]"])
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

