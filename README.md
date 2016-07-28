phoenix_integration
========

## Documentation

You can read [the full documentation here](https://hexdocs.pm/phoenix_integration).

## Overview

PhoenixIntegration is set of lightweight, server-side integration test functions for Phoenix.
Works within the existing `Phoenix.ConnTest` framework and emphasizes both speed and readability.

The goal is to chain together a string of requests and assertions that thoroughly
exercise your application in as lightweight and readable manner as possible.

Each function accepts a conn and some other data, and returns a conn intended to be
passed into the next function via a pipe.

```elixir
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

test "Create new user", %{conn: conn} do
  # get the root index page
  get( conn, page_path(conn, :index) )
  # click/follow through the various about pages
  |> follow_link( "Sign Up" )
  |> follow_form( %{ user: %{
        name: "New User",
        email: "user@example.com",
        password: "test.password",
        confirm_password: "test.password"
      }} )
  |> assert_response(
      status: 200,
      path: page_path(conn, :index),
      html: "New User" )
end
```

## Installation

### Step 1

Tell phoenix_integration what Endpoint to use.
To do this, add the following to your `config/test.exs` file

```elixir
config :phoenix_integration,
  endpoint: MyApp.Endpoint
```

Where MyApp is the name of your app.

### Step 2

Add PhoenixIntegration to the deps section of your application's `mix.exs` file

```elixir
defp deps do
  [
    # ...
    {:phoenix_integration, "~> 0.1.0"}
    # ...
  ]
end
```
### Step 3

Run `mix deps.get` on the command line.

## Documentation

You can read [the full documentation here](https://hexdocs.pm/phoenix_integration).

