defmodule PhoenixIntegration.FormSupport do
  alias PhoenixIntegration.Form.{Tag,TreeCreation}

  def input_to_tag(fragment),
    do: Floki.parse_fragment!(fragment) |> Tag.new!


  # These functions are used when you want to build trees
  # from Tags (*not* Floki data structures), and you don't
  # care about errors, etc. 
  def test_tree!(tags) when is_list(tags) do
    Enum.reduce(tags, %{}, fn tag, acc ->
      TreeCreation.add_tag!(acc, tag)
    end)
  end

  def test_tree!(tag), do: test_tree!([tag])


  IO.puts "Delete this when all the error handling tests are done."
  def build_tree(tags) when is_list(tags) do
    Enum.reduce_while(tags, %{}, fn tag, acc ->
      case TreeCreation.add_tag(acc, tag) do
        {:ok, new_tree} -> {:cont, new_tree}
        err -> {:halt, err}
      end
    end)
  end

  def form_for(html_snippet) do
    html =
      """
      <form accept-charset="UTF-8" action="/form" method="post" id="proper_form">
        #{html_snippet}
      </form>
      """

    {:ok, _action, _method, form}  =   
      PhoenixIntegration.Requests.test_find_html_form(
        html, "#proper_form", nil, "form")
    form
  end
end
