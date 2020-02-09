defmodule PhoenixIntegration.Details.TagTest do
  use ExUnit.Case, async: true
  import PhoenixIntegration.Assertions.Map
  import PhoenixIntegration.FormSupport
  alias PhoenixIntegration.Form.Tag

  describe "common transformations" do
    test "single-valued names" do
      floki_tag = """
        <some_tag_name name="top_level[animal]" value="x">
      """
      |> Floki.parse_fragment!

      floki_tag
      |> Tag.new!
      |> assert_fields(has_list_value: false,
                       values: ["x"],
                       name: "top_level[animal]",
                       path: [:top_level, :animal],
                       tag: "some_tag_name",
                       original: floki_tag)
    end

    
    test "multi-valued ([]-ending) names" do
      floki_tag = """
        <some_tag_name name="top_level[animals][]" value="x">
      """
      |> Floki.parse_fragment!

      floki_tag
      |> Tag.new!
      |> assert_fields(has_list_value: true,
                       values: ["x"],
                       name: "top_level[animals][]",
                       path: [:top_level, :animals],
                       tag: "some_tag_name",
                       original: floki_tag)
    end
  end

  test "fields with types record them" do
    """
    <input type="text" name="top_level[name]" value="name">
    """
    |> Floki.parse_fragment!
    |> Tag.new!
    |> assert_field(type: "text")
  end


  describe "checkbox special cases" do
    # Special cases for checkboxes as described in
    # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/Input/checkbox
    test "a checkbox that's omitted `checked`" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" value="x">
      """, []
    end

    test "a checkbox that has any value for `checked`" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" checked="true" value="x">
      """, ["x"]
    end

    test "a checkbox that is checked but has no explicit value" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][a]" checked="true">
      """, ["on"]
    end

    test "a checkbox that's part of an list has the same effect" do
      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" value="x">
      """, []

      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" checked="true" value="x">
      """, ["x"]

      assert_input_values """
        <input type="checkbox" name="top_level[grades][]" checked="anything">
      """, ["on"]
    end
  end

  test "textareas" do
    """
    <textarea class="form-control" id="user_story" name="user[story]">Initial user story</textarea>
    """
    |> Floki.parse_fragment!
    |> Tag.new!
    |> assert_fields(values: ["Initial user story"],
                     tag: "textarea",
                     name: "user[story]",
                     path: [:user, :story])
  end

  describe "select" do
    test "a scalar form with one value selected" do
      """
      <select class="form-control" id="user_type" name="user[type]">
        <option value="type_one">One</option>
        <option selected="selected" value="type_two">Two</option>
        <option value="type_three">Three</option>
      </select>
      """
      |> Floki.parse_fragment!
      |> Tag.new!
      |> assert_fields(values: ["type_two"],
                       has_list_value: false,
                       tag: "select",
                       name: "user[type]",
                       path: [:user, :type])
    end

    # "if no value attribute is included, the value defaults to the
    # text contained inside the element" -
    # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/select
    test "a scalar form with no `value` attribute" do
      """
      <select class="form-control" id="user_type" name="user[type]">
        <option>One</option>
        <option selected="selected">Two</option>
        <option>Three</option>
      </select>
      """
      |> Floki.parse_fragment!
      |> Tag.new!
      |> assert_field(values: ["Two"],
                      has_list_value: false)
    end

    test "a simple form with no value selected" do
      """
      <select class="form-control" id="user_type" name="user[type]">
        <option value="type_one">One</option>
        <option value="type_two">Two</option>
        <option value="type_three">Three</option>
      </select>
      """
      |> Floki.parse_fragment!
      |> Tag.new!
      |> assert_field(values: [],
                      has_list_value: false)
    end

    test "a multiple select" do
      """
      <select id="user_roles" name="user[roles][]">
        <option value="1" selected="selected">Admin</option>
        <option value="2">Power User</option>
        <option value="3" selected="selected">Plain User</option>
      </select>
      """
      |> Floki.parse_fragment!
      |> Tag.new!
      |> assert_field(values: ["1", "3"],
                      name: "user[roles][]",
                      path: [:user, :roles],
                      has_list_value: true)
    end
  end

  

  defp assert_input_values(fragment, values) do
    assert input_to_tag(fragment).values == values
  end
end
