defmodule PhoenixIntegration.CheckboxTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest
  import PhoenixIntegration.Requests, only: [test_build_form_data: 2]
  @endpoint PhoenixIntegration.TestEndpoint

  setup do
    [form_with_hidden: find_form("#with_hidden"),
     form_without_hidden: find_form("#without_hidden")]
  end


  test "diagnostic for issue 45" do
    result = 
      find_form("#issue45")
      |> IO.inspect(label: "form as read")
      |> PhoenixIntegration.Form.TreeCreation.build_tree
      |> IO.inspect(label: "form converted to a tree")
      |> Map.get(:tree)
      |> PhoenixIntegration.Form.TreeEdit.apply_edits(%{ab_test: %{environments: ["ci"]}})
      |> IO.inspect(label: "edited tree")

    assert {:ok, _} = result
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
          %{"2" => "true"}}})

      assert checked == %{"1": "false", "2": "true"}
    end

    test "setting all the values", %{form_with_hidden: form} do
      %{animals: %{chosen: checked}} =
        test_build_form_data(form, %{animals: %{chosen: 
          %{"1" => "false", "2" => "true"}}})

      assert checked == %{"1": "false", "2": "true"}
    end
  end

  # ----------------------------------------------------------------------------
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
      # It would be unusual for a form to *only* have non-values, but - 
      # if it does - not even the top level key will be available to the
      # controller action.
      assert %{} == test_build_form_data(form, %{})
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
  end

  # ----------------------------------------------------------------------------
  def find_form(id) do 
    html = get(build_conn(:get, "/"), "/checkbox").resp_body

    {:ok, _action, _method, form} =
      PhoenixIntegration.Requests.test_find_html_form(html, id, nil, "form")

    form
  end

  def assert_name_type_value(source, name, type, value), 
    do: assert source == [{"name", name}, {"type", type}, {"value", value}]
end
