defmodule PhoenixIntegration.FormSupport do
  alias PhoenixIntegration.Form.{Tag,TreeCreation}

  def input_to_tag(fragment),
    do: Floki.parse_fragment!(fragment) |> Tag.new!

  # These functions are used when you want to build trees
  # from Tags (*not* Floki data structures), and you don't
  # care about errors, etc. 
  def test_tree!(tag) when not is_list(tag),
    do: test_tree!([tag])
  def test_tree!(tags) when is_list(tags),
    do: Enum.reduce(tags, %{}, &create_one/2)

  defp create_one(fragment, acc) when is_binary(fragment), 
    do: create_one(input_to_tag(fragment), acc)
  defp create_one(tag, acc), 
    do: TreeCreation.add_tag!(acc, tag)

    def form_for(html_snippet, opts \\ []) do 
      case Keyword.get(opts, :id, true) do
        true -> 
          form_for(html_snippet, ~s|id="proper_form"|, "#proper_form")
        false ->
          form_for(html_snippet, "", nil)
      end
    end

    def form_for(html_snippet, id_attr, identifier) do
      html =
        """
        <form accept-charset="UTF-8" action="/form" method="post" #{id_attr}>
        #{html_snippet}
        </form>
        """
      {:ok, _action, _method, form}  =   
        PhoenixIntegration.Requests.test_find_html_form(
          html, identifier, nil, "form")
      form
    end
end
