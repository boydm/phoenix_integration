defmodule PhoenixIntegration.Form.Change do
  @moduledoc """
  The test asks that a form value be changed. This struct contains 
  the information required to make the change.
  """

  defstruct path: [], value: nil


  def to(path, new_value) when is_list(path) do
    %__MODULE__{path: path, value: new_value}
  end
end
