defmodule PhoenixIntegration.Form.UserValue do
  @moduledoc """
  This is a representation of a value provided by the user to
  add into an existing `Form.Tree`.

  It contains a subset of `Form.Tag` fields.
  """
  alias PhoenixIntegration.Form.{Tag,UserValue}

  defstruct has_array_value: false,
    values: [],
    path: []


  def from(%Tag{} = tag, [except: opts]) do
    struct(__MODULE__,
      Map.merge(
        Map.from_struct(tag),
        Enum.into(opts, %{})))
  end
  
end
