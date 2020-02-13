defmodule PhoenixIntegration.Form.Change do
  alias PhoenixIntegration.Form.Common
  @moduledoc """
  The test asks that a form value be changed. This struct contains 
  the information required to make the change.
  """

  defstruct path: [], value: nil, ignore_if_missing_from_form: false

  def changes(tree), do: changes(tree, %__MODULE__{})

  defp changes(tree, %__MODULE__{} = state) when is_map(tree) do
    if do_is_struct(tree) do
      changes(Map.from_struct(tree), note_struct(state))
    else
      Enum.flat_map(tree, fn {key, value} ->
        changes(value, note_longer_path(state, key))
      end)
    end 
  end

  defp changes(value, state) do
    [%{state |
       path: Enum.reverse(state.path),
       value: value
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
