defmodule PhoenixIntegration.FormsTest do
  use ExUnit.Case, async: true
  use Phoenix.ConnTest
  @endpoint PhoenixIntegration.TestEndpoint

  # @href_first_get   "/links/first"
  # @href_second_get  "https://www.example.com/links/second"

  @form_action "/form"
  @form_method "put"
  @form_id "#proper_form"

  @user_data %{
    user: %{
      name: "User Name",
      type: "type_one",
      story: "Updated story.",
      species: "centauri"
    }
  }

  # ============================================================================
  # set up context
  setup do
    html = get(build_conn(:get, "/"), "/sample").resp_body

    {:ok, _action, _method, form} =
      PhoenixIntegration.Requests.test_find_html_form(html, @form_id, nil, "form")

    %{html: html, form: form}
  end

  # ============================================================================
  # find form

  test "find form via uri or path", %{html: html} do
    found = PhoenixIntegration.Requests.test_find_html_form(html, @form_action, nil, "form")
    {:ok, @form_action, @form_method, _form} = found
  end

  test "find form via id", %{html: html} do
    found = PhoenixIntegration.Requests.test_find_html_form(html, @form_id, nil, "form")
    {:ok, @form_action, @form_method, _form} = found
  end

  test "find form via internal text", %{html: html} do
    found =
      PhoenixIntegration.Requests.test_find_html_form(
        html,
        "Text in the proper form",
        nil,
        "form"
      )

    {:ok, @form_action, @form_method, _form} = found
  end

  test "find form raises on missing path", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_form(html, "/invalid/path", nil, "form")
    end
  end

  test "find form raises on invalid id", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_form(html, "#other", nil, "form")
    end
  end

  test "find form raises on missing text", %{html: html} do
    assert_raise RuntimeError, fn ->
      PhoenixIntegration.Requests.test_find_html_form(html, "Invalid Text", nil, "form")
    end
  end

  # ============================================================================
  # build form data to send

  test "build form data works", %{form: form} do
    data = PhoenixIntegration.Requests.test_build_form_data(form, @user_data)
    %{user: user_params} = data
    assert user_params.name == @user_data.user.name
    assert user_params.type == @user_data.user.type
    assert user_params.story == @user_data.user.story
    assert user_params.species == @user_data.user.species
  end

  test "build form data sets just text field", %{form: form} do
    user_data = %{user: %{name: "Just Name"}}
    data = PhoenixIntegration.Requests.test_build_form_data(form, user_data)
    %{user: user_params} = data
    assert user_params.name == "Just Name"
    assert user_params.type == "type_two"
    assert user_params.story == "Initial user story"
    assert user_params.species == "human"
  end

  test "build form data sets just select field", %{form: form} do
    user_data = %{user: %{type: "type_three"}}
    data = PhoenixIntegration.Requests.test_build_form_data(form, user_data)
    %{user: user_params} = data
    assert user_params.name == "Initial Name"
    assert user_params.type == "type_three"
    assert user_params.story == "Initial user story"
    assert user_params.species == "human"
  end

  test "build form data sets just text area", %{form: form} do
    user_data = %{user: %{story: "Just story."}}
    data = PhoenixIntegration.Requests.test_build_form_data(form, user_data)
    %{user: user_params} = data
    assert user_params.name == "Initial Name"
    assert user_params.type == "type_two"
    assert user_params.story == "Just story."
    assert user_params.species == "human"
  end

  test "build form data sets just radio", %{form: form} do
    user_data = %{user: %{species: "narn"}}
    data = PhoenixIntegration.Requests.test_build_form_data(form, user_data)
    %{user: user_params} = data
    assert user_params.name == "Initial Name"
    assert user_params.type == "type_two"
    assert user_params.story == "Initial user story"
    assert user_params.species == "narn"
  end

  test "build form data sets nested forms", %{form: form} do
    user_data = %{
      user: %{
        tag: %{name: "new tag"},
        friends: %{"0": %{address: %{city: %{zip: "67890"}}}}
      }
    }

    data = PhoenixIntegration.Requests.test_build_form_data(form, user_data)
    %{user: user_params} = data
    assert user_params.name == "Initial Name"
    assert user_params.type == "type_two"
    assert user_params.story == "Initial user story"
    assert user_params.species == "human"
    assert user_params.tag.name == "new tag"
    assert user_params.friends[:"0"].address.city.zip == "67890"
  end
end
