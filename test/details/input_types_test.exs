defmodule PhoenixIntegration.RequestTest do
  use ExUnit.Case
  use Phoenix.ConnTest, async: true
  alias PhoenixIntegration.Form.{TreeCreation,TreeEdit,TreeFinish}
  import PhoenixIntegration.Assertions.Map

  @endpoint PhoenixIntegration.TestEndpoint
  use PhoenixIntegration

  # Note that input type="checkbox" and type="radio" are checked elsewhere
  setup do
    html = get(build_conn(:get, "/"), "/input_types").resp_body

    {:ok, _action, _method, form} =
      PhoenixIntegration.Requests.test_find_html_form(html, "#input_types", nil, "form")

    created = TreeCreation.build_tree(form)
    [created: created, tree: created.tree]
  end

  test "all text-like fields have a value initialized to the empty string",
    %{tree: tree} do
    uninitialized_fields = %{user:
      %{date: "",
        datetime_local: "",
        email: "",
        file: "",
        hidden: "",
        month: "",
        number: "",
        password: "",
        photo: "",
        range: "",
        search: "",
        tel: "",
        text: "",
        time: "",
        url: "",
        week: "",
        datetime: ""
      }}

    assert TreeFinish.to_action_params(tree) == uninitialized_fields
  end

  test "edits apply normally", %{tree: tree} do 
    edits = %{user:
      %{date: "date",
        datetime_local: "datetime_local",
        email: "email",
        file: "file",
        hidden: "hidden",
        month: "month",
        number: "number",
        password: "password",
        photo: "photo",
        range: "range",
        search: "search",
        tel: "tel",
        text: "text",
        time: "time",
        url: "url",
        week: "week",
        datetime: "datetime"
      }}
    
    assert {:ok, edited} = TreeEdit.apply_edits(tree, edits)
    finished = TreeFinish.to_action_params(edited)
    assert finished == edits
  end

  test "explicitly that there are no warnings", %{created: created} do
    assert created.warnings == []
  end

  test "explicitly that button-type inputs are not included", %{tree: tree} do
    refute Map.get(tree.user, :button)
    refute Map.get(tree.user, :image)
    refute Map.get(tree.user, :reset)
    refute Map.get(tree.user, :submit)
  end
end  
