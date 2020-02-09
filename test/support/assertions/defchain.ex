defmodule PhoenixIntegration.Assertions.Defchain do

  @doc """
  Create an assertion that can be chained together with other
  similar assertions, like this:

      get(conn, ...)
      |> assert_will_post_to(:set_fresh_password)
      |> assert_user_sees(required_1)
      |> assert_user_sees(required_2)
     
  Assertions are created by using `defchain` instead of `def`:

      defchain assert_user_sees(conn, claim), do: ...
      defchain assert_purpose(conn, purpose), do: ...
  """

  defmacro defchain(head, do: body) do
    quote do
      def unquote(head) do
        _called_for_side_effect = unquote(body)
        unquote(value_arg(head))
      end
    end
  end

  # A `when...` clause in a def produces a rather peculiar syntax tree.
  # Although it's textually within the `def`, in the tree structure, it's
  # outside it.
  defp value_arg(head) do
    case head do
      {:when, _env, [true_head | _]} ->
        value_arg(true_head)
      _ -> 
        {_name, _, args} = head
        [value_arg | _] = args
        value_arg
    end
  end
end
