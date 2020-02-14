defmodule PhoenixIntegration.CheckboxTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest
  import PhoenixIntegration.Requests, only: [test_build_form_data: 2]
  @endpoint PhoenixIntegration.TestEndpoint

  setup do
    [form_with_hidden: find_form("#with_hidden"),
     form_without_hidden: find_form("#without_hidden")]
  end

  # The "hidden input hack" uses two `input` tags for each checkbox:
  #
  #   <input type="hidden"   value="false" name="name">
  #   <input type="checkbox" value="true"  name="name">
  #
  # If the checkbox is not checked, the browser is not to include its
  # name/value pair in the form parameters. However, the `hidden`
  # input is included, so the backend receives "name" => "false".
  #
  # If the checkbox has been clicked, the browser includes both inputs. Since
  # they both have the same `name`, the second overrides the first, so
  # the backend receives "name" => "true"

  describe "the hidden input hack" do 
    test "what a checkbox with a hidden 'false' input looks like",
      %{form_with_hidden: form} do
      
      {"form", _,
       [{"input", hidden1, _},
        {"input", checkbox1, _},
        {"input", hidden2, _},
        {"input", checkbox2, _}
       ]
      } = form
      
      assert_name_type_value(hidden1,   "animals[chosen][1]", "hidden",   "false")
      assert_name_type_value(checkbox1, "animals[chosen][1]", "checkbox", "true")
      assert_name_type_value(hidden2,   "animals[chosen][2]", "hidden",   "false")
      assert_name_type_value(checkbox2, "animals[chosen][2]", "checkbox", "true")
    end

    test "if not 'checked' by the test, the default (hidden) values are used",
      %{form_with_hidden: form} do
      
      %{animals: %{chosen: checked}} =
        test_build_form_data(form, %{})
      assert checked == %{"1": "false", "2": "false"}
    end

    test "set just one value, check that the other one is retained",
      %{form_with_hidden: form} do

      %{animals: %{chosen: checked}} =
        test_build_form_data(form, %{animals: %{chosen: 
          %{:"2" => "true"}}})

      assert checked == %{"1": "false", "2": "true"}
    end

    test "setting all the values", %{form_with_hidden: form} do
      %{animals: %{chosen: checked}} =
        test_build_form_data(form, %{animals: %{chosen: 
          %{"1" => "false", "2" => "true"}}})

      assert checked == %{"1": "false", "2": "true"}
    end
  end

  describe "without the hidden input" do 
    test "what a checkbox looks like",
      %{form_without_hidden: form} do
      
      {"form", _,
       [{"input", checkbox1, _},
        {"input", checkbox2, _}
       ]
      } = form
      
      assert_name_type_value(checkbox1, "animals[chosen][1]", "checkbox", "true")
      assert_name_type_value(checkbox2, "animals[chosen][2]", "checkbox", "true")
    end

    test "if nothing is 'checked' in the test, no values are sent",
      %{form_without_hidden: form} do

      # I think there's no way, given HTTP, to avoid having no
      # `chosen` field when nothing has been checked. That is, we
      # can't match on this:
      #
      #  %{animals: %{chosen: %{}}}
      assert %{animals: %{}} =
        test_build_form_data(form, %{})
    end

    test "if one value is checked in the test, only that value is sent",
      %{form_without_hidden: form} do

      %{animals: %{chosen: checked}} =
        test_build_form_data(form, %{animals: %{chosen: 
          %{"1" => "true"}}})

      assert checked == %{:"1" => "true"}
    end

    test "if all values are set, they're all sent",
      %{form_without_hidden: form} do

      %{animals: %{chosen: checked}} =
        test_build_form_data(form, %{animals: %{chosen: 
          %{"1" => "true", "2" => "true"}}})

      assert checked == %{:"1" => "true", :"2" => "true"}
    end

    @tag :skip  ## This fails
    test "values that are explicitly set false still should not be sent",
      # I argue that someone NOT using the hidden hack would never expect
      # to get a false value. I didn't in the application that started all this.
      # We could say "well, just don't ever set a value to false then" but
      # someone might do that to better mimic what a bunch of checkboxes would
      # look like on the screen. Nicer not to surprise them.

      # Later: it's not actually possible to tell what's an actual false
      # value. We'd have to add something like this:
      #
      # %{:"1" => :checked, :"2" => :unchecked}}})
      %{form_without_hidden: form} do

      %{animals: %{chosen: checked}} =
        test_build_form_data(form, %{animals: %{chosen: 
          %{:"1" => "true", :"2" => "false"}}})

      assert checked == %{:"1" => "true"}
    end
  end

  def find_form(id) do 
    html = get(build_conn(:get, "/"), "/checkbox").resp_body

    {:ok, _action, _method, form} =
      PhoenixIntegration.Requests.test_find_html_form(html, id, nil, "form")

    form
  end

  def assert_name_type_value(source, name, type, value), 
    do: assert source == [{"name", name}, {"type", type}, {"value", value}]
end
