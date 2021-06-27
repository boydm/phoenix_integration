defmodule PhoenixIntegration do
  @moduledoc """
  Lightweight server-side integration test functions for Phoenix.

  Works within the existing `Phoenix.ConnTest` framework and emphasizes both
  speed and readability.

  ## Configuration

  ### Step 1

  You need to tell `:phoenix_integration` which endpoint to use. Add the
  following to your phoenix application's `config/test.exs` file.

  ```elixir
  config :phoenix_integration,
    endpoint: MyApp.Endpoint
  ```

  Where MyApp is the name of your application.

  Do this up before compiling phoenix_integration as part of step 2. If you
  change the endpoint in the config file, you will need to recompile the
  phoenix_integration dependency.

  Phoenix_integration will produce warnings if your HTML likely doesn't do what
  you meant. (For example, it will warn you if two text fields have the same
  name.) You can turn those off by adding `warnings: false` to the config.

  ### Step 2

  Add `:phoenix_integration` to the deps section of your application's
  `mix.exs` file:

  ```elixir
  defp deps do
    [
      # ...
      {:phoenix_integration, "~> 0.8", only: :test}
      # ...
    ]
  end
  ```

  Don't forget to run `mix deps.get`.

  ### Step 3

  Create a `test/support/integration_case.ex` file. Mine simply looks like this:

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

  Alternately you could place the call to `use PhoenixIntegration` in your
  conn_case.ex file. Just make sure it is after the definition of `@endpoint`.

  ## Overview

  `:phoenix_integration` provides two assertion and six request functions to be
  used alongside the existing `get`, `post`, `put`, `patch`, and `delete`
  utilities inside of a `Phoenix.ConnTest` test suite.

  The goal is to chain together a string of requests and assertions that thouroughly
  exercise your application in as lightweight and readable manner as possible.

  Each function accepts a conn and some other data, and returns a conn intended to be
  passed into the next function via a pipe.

  ### Examples

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

  ### Simulate multiple users

  Since all user state is held in the conn that is being passed around (just like when
  a user is hitting your application in a browser), you can simulate multiple users
  simply by tracking separate conns for them.

  In the example below, I'm assuming an application-specific `test_sign_in` function, which
  itself uses the `follow_*` functions to sign a given user in.

  Notice how `user_conn` is tracked and reused. This keeps the state the user builds
  up as the various links are followed, just like it would be when a proper browser is used.

  ### Examples

      test "admin grants a user permissions", %{conn: conn, user: user, admin: admin} do
        # sign in the user and admin
        user_conn = test_sign_in( conn, user )
        admin_conn = test_sign_in( conn, admin )

        # user can't see a restricted page
        user_conn = get( user_conn, page_path(conn, :index) )
        |> follow_link( "Restricted" )
        |> assert_response( status: 200, path: session_path(conn, :new) )
        |> refute_response( body: "Restricted Content" )

        # admin grants the user permission
        get( admin_conn, page_path(conn, :index) )
        |> follow_link( "Admin Dashboard" )
        |> follow_form( %{ user: %{
              permissoin: "ok_to_do_thing"
            }} )
        |> assert_response(
            status: 200,
            path: admin_path(conn, :index),
            html: "Permission Granted" )

        # the user should now be able to see the restricted page
        get( user_conn, page_path(conn, :index) )
        |> follow_link( "Restricted" )
        |> assert_response(
            status: 200,
            path: restricted_path(conn, :index),
            html: "Restricted Content"
          )
      end

  ### Tip

  You can intermix `IO.inspect` calls in the pipe chain to help with debugging. This
  will print the current state of the conn into the console.

      test "Basic page flow", %{conn: conn} do
        # get the root index page
        get( conn, page_path(conn, :index) )
        |> follow_link( "About Us" )
        |> IO.inspect
        |> follow_link( "Home" )
        |> assert_response( status: 200, path: page_path(conn, :index) )
      end

  I like to use `assert_response` pretty heavily to make sure the content I expect
  is really there and to make sure I am traveling to the right locations.

      test "Basic page flow", %{conn: conn} do
        get(conn, page_path(conn, :index) )
        |> assert_response(
            status: 200,
            path: page_path(conn, :index),
            html: "Test App"
          )
        |> follow_link( "About" )
        |> assert_response(
            status: 200,
            path: about_path(conn, :index),
            html: "About Test App"
          )
        |> follow_link( "Contact" )
        |> assert_response(
            status: 200,
            path: about_path(conn, :contact),
            html: "Contact"
          )
        |> follow_link( "Home" )
        |> assert_response(
            status: 200,
            path: page_path(conn, :index),
            html: "Test App"
          )
      end

  ### What phoenix_integration is NOT

  phoenix_integration is not a client-side acceptence test suite. It does not use
  a real browser and does not exercise javascript code that lives there. It's focus
  is on fast, readable, server-side integration.

  Try using a tool like [`Hound`](https://hex.pm/packages/hound) for full-stack
  integration tests.
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixIntegration.Assertions
      import PhoenixIntegration.Requests
    end
  end
end
