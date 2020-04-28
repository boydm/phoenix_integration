defmodule PhoenixIntegration.Details.MessagesTest do
  use ExUnit.Case
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

  describe "warnings when turning a form into a tree" do
    test "a tag without a name" do
      html = ~S| <input type="radio"/> |
      form = form_for html

      assert_substrings(will_fail_to_create_tree(form),
        [Messages.get(:tag_has_no_name),
         "It can't be included in the params sent to the controller",
         String.trim(html)
        ])
    end

    test "a nonsensical name" do
      html = ~S| <input name="" type="radio"/> |
      form = form_for html

      assert_substrings(will_fail_to_create_tree(form),
        [Messages.get(:empty_name),
         String.trim(html)
        ])
    end

    test "a less-nested name follows a more deeply nexted name" do
      # Phoenix (currently) retains the earlier (more nested) value.
      html = """
        <input type="text" name="top_level[param][subparam]" value="y">
        <input type="text" name="top_level[param]"           value="x">
      """
      form = form_for html

      assert_substrings(will_fail_to_create_tree(form),
        [Messages.get(:form_conflicting_paths),
         "top_level[param][subparam]",
         "top_level[param]"
        ])
    end

    test "a more-nested name follows a shallower one" do
      # Phoenix (currently) loses the original value.
      html = """
        <input type="text" name="top_level[param]"           value="x">
        <input type="text" name="top_level[param][subparam]" value="y">
      """
      form = form_for html

      assert_substrings(will_fail_to_create_tree(form),
        [Messages.get(:form_conflicting_paths),
         "top_level[param]",
         "top_level[param][subparam]"
        ])
    end
  end

  # ----------------------------------------------------------------------------
  describe "errors when applying test override values" do 
    test "setting missing field (as a leaf)" do
      form = form_for """
        <input id="user_tag_name" name="user[tag]" type="text" value="tag">
        """
      edit_tree = %{user: %{i_made_a_typo: "new value"}}

      assert_substrings(will_fail_to_edit_tree(form, edit_tree), 
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
      edit_tree = %{i_made_a_typo: %{tag: "new value"}}

      assert_substrings(will_fail_to_edit_tree(form, edit_tree), 
        [ Messages.get(:no_such_name_in_form),
          "Is this a typo?", ":i_made_a_typo",
          "[:i_made_a_typo, :tag]", "new value"
        ])
    end

    test "setting a prefix of a field" do
      form = form_for """
        <input name="user[tag][name]" type="text" value="tag">
        """
      edit_tree = %{user: %{tag: "new value"}}

      assert_substrings(will_fail_to_edit_tree(form, edit_tree), 
        [ Messages.get(:no_such_name_in_form),
          "You provided only a prefix of all the available names.",
          "Here is your path", "[:user, :tag]",
          "Here is an available name", "user[tag][name]"])
    end

    test "an edit tree deeper than the actual form" do
      form = form_for """
        <input name="user[tag]" type="text" value="tag">
        """
      edit_tree = %{user: %{tag: %{name: "new value"}}}

      assert_substrings(will_fail_to_edit_tree(form, edit_tree), 
        [ Messages.get(:no_such_name_in_form),
          "Your path is longer than the names it should match",
          "Here is your path", "[:user, :tag, :name]",
          "Here is an available name", "user[tag]"])
    end

    test "a too-long path will not be fooled by a key in a Tag" do
      form = form_for """
        <input name="user[tag]" type="text" value="tag">
        """
      edit_tree = %{user: %{tag: %{name: %{lower: "new value"}}}}

      assert_substrings(will_fail_to_edit_tree(form, edit_tree), 
        [ Messages.get(:no_such_name_in_form),
          "Your path is longer than the names it should match",
          "Here is your path", "[:user, :tag, :name, :lower]",
          "Here is an available name", "user[tag]"])
    end

    test "setting a list tag to a scalar" do
      form = form_for """
        <input name="user[tag][]" type="text" value="tag">
        """
      edit_tree = %{user: %{tag: "skittish"}}

      assert_substrings(will_fail_to_edit_tree(form, edit_tree), 
        [ Messages.get(:arity_clash),
          "the name of the tag you're setting ends in `[]`", "user[tag][]",
          "should be a list", "skittish"])
    end

    test "setting a scalar tag to a list" do
      form = form_for """
        <input name="user[tag]" type="text" value="tag">
        """
      edit_tree = %{user: %{tag: ["skittish"]}}

      assert_substrings(will_fail_to_edit_tree(form, edit_tree), 
        [ Messages.get(:arity_clash),
          "value you want", ~s|["skittish"]|,
          "doesn't end in `[]`", "user[tag]"])
    end

    test "you can get more than one error" do
      form = form_for """
        <input id="user_tag_name" name="user[tag]" type="text" value="tag">
        <input name="user[keys][]" type="checkbox" value="true">
        <input name="user[keys][]" type="checkbox" value="true">
        """
      edit_tree = %{user: %{i_made_a_typo: "new value",
                            keys: "false"}}

      assert_substrings(will_fail_to_edit_tree(form, edit_tree), 
        [ Messages.get(:no_such_name_in_form),
          "Is this a typo?", ":i_made_a_typo",
          "action:", "/form",
          "id:", "proper_form",
          "[:user, :i_made_a_typo]", "new value",

          Messages.get(:arity_clash),
          "the name of the tag you're setting ends in `[]`", "user[keys][]",
          "should be a list", "false"])
    end

    test "it's ok if a tag doesn't have an id" do
      form = form_for """
        <form accept-charset="UTF-8" action="/form" method="post">
          <input_name" name="user[tag]" type="text" value="tag">
        </form>
      """, id: false
      edit_tree = %{user: %{i_made_a_typo: "new value"}}

      message = capture_io(will_fail_to_edit_tree(form, edit_tree))
      refute String.contains?(message, "id:")
      assert String.contains?(message, ":i_made_a_typo")
    end
  end

  # ----------------------------------------------------------------------------
  def will_fail_to_create_tree(form) do
    fn ->
      PhoenixIntegration.Requests.test_build_form_data(form, %{})
    end
  end

  def will_fail_to_edit_tree(form, edit_tree) do
    fn -> 
      assert_raise(RuntimeError, fn ->
        PhoenixIntegration.Requests.test_build_form_data(form, edit_tree)
      end)
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

