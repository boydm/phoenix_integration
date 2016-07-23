defmodule PhoenixIntegration do


  defmacro __using__(_opts) do
    quote do
      import PhoenixIntegration.Assertions
      import PhoenixIntegration.Requests
    end # quote
  end # defmacro


end
