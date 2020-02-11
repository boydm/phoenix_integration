defmodule PhoenixIntegration.Form.Util do
  def symbolize(anything), do: to_string(anything) |> String.to_atom
end
