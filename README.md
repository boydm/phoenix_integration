phoenix_integration
========

## Documentation

You can read [the full documentation here](https://hexdocs.pm/phoenix_integration).

## Overview

PhoenixIntegration is set of lightweight, server-side integration test functions for Phoenix.
Works within the existing `Phoenix.ConnTest` framework and emphasizes both speed and readability.

The goal is to chain together a string of requests and assertions that thoroughly
exercise your application in as lightweight and readable manner as possible.

I love the pipe `|>` command in Elixir. By using the pipe to chain together calls in an integration test, phoenix_integration is able to be very readable. Tight integration with Phoenix.ConnTest means the call all use the fast-path to your application for speed.

## Installation

### Step 1

Add PhoenixIntegration to the deps section of your application's `mix.exs` file

```elixir
defp deps do
  [
    # ...
    {:phoenix_integration, "~> 0.1"}
    # ...
  ]
end
```

Don't forget to run `mix deps.get`

### Step 2
Create a test/support/integration_case.ex file. Mine simply looks like this:

```elixir
defmodule MyApp.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use MyApp.ConnCase
      use PhoenixIntegration
    end
  end

end

```

Alternately you could place the call to `use PhoenixIntegration` in your conn_case.ex file. Just make sure it is after the definition of `@endpoint`.

### Step 3
Start writing integration tests. They should use your integration_conn.ex file. Here is a full example (just the name of the app is changed). This is from the location test/integration/page_integration_test.exs

```elixir
defmodule MyApp.AboutIntegrationTest do
  use Loom.IntegrationCase, async: true

  test "Basic page flow", %{conn: conn} do
    # get the root index page
    get( conn, page_path(conn, :index) )
    # click/follow through the various about pages
    |> follow_link( "About Us" )
    |> follow_link( "Contact" )
    |> follow_link( "Privacy" )
    |> follow_link( "Terms of Service" )
    |> follow_link( "Home" )
    |> assert_response( status: 200, path: page_path(conn, :index) )
  end

end
```

Each function in phoenix_integration accepts a conn and some other data, and returns a conn. This conn is intended to be passed into the next function via a pipe. to build up a clear, readable chain of events in your test.


## Documentation

You can read [the full documentation here](https://hexdocs.pm/phoenix_integration).

