defmodule PhoenixIntegration do

  @moduledoc """
  Lightweight integration test support for Phoenix. Extends the existing
  Phoenix.ConnTest framework.

  ## Overview

  Overview `"topic:subtopic"` goes here

    channel "room:*", MyApp.RoomChannel

  More stuff goes here
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixIntegration.Assertions
      import PhoenixIntegration.Requests
    end # quote
  end # defmacro


end
