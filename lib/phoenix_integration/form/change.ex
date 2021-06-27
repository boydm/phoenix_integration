defmodule PhoenixIntegration.Form.Change do
  alias PhoenixIntegration.Form.Common
  @moduledoc false

  # A test asks that a form value be changed. This struct contains
  # the information required to make the change.

  defstruct path: [], value: nil, ignore_if_missing_from_form: false

  def changes(tree), do: changes(tree, %__MODULE__{})

  defp changes(node, state) do
    case classify(node) do
      :descend_map ->
        Enum.flat_map(node, fn {key, value} ->
          changes(value, note_longer_path(state, key))
        end)
      :descend_struct ->
        changes(Map.from_struct(node), note_struct(state))
      :finish_descent ->
        finish_descent(node, state)
    end
  end

  def classify(node) when not is_map(node),
    do: :finish_descent

  def classify(node) when is_map(node) do
    case {do_is_struct(node), node} do
      {false,              _} -> :descend_map
      {true,  %Plug.Upload{}} -> :finish_descent
      {true,               _} -> :descend_struct
    end
  end

  def finish_descent(leaf, state) do
    [%{state |
       path: Enum.reverse(state.path),
       value: leaf
      }]
  end


  # This is in the latest version of Elixir, but let's have
  # some backward compatibility.
  defp do_is_struct(v) do
    v |> Map.has_key?(:__struct__)
  end

  defp note_struct(%__MODULE__{} = state),
    do: %{state | ignore_if_missing_from_form: true}

  defp note_longer_path(%__MODULE__{} = state, key),
    do: %{state | path: [Common.symbolize(key) | state.path] }

end
