# PhoenixIntegration

[![Build Status](https://travis-ci.org/boydm/phoenix_integration.svg?branch=master)](https://travis-ci.org/boydm/phoenix_integration)
[![Inline docs](http://inch-ci.org/github/boydm/phoenix_integration.svg?branch=master)](http://inch-ci.org/github/boydm/phoenix_integration)
[![Module Version](https://img.shields.io/hexpm/v/phoenix_integration.svg)](https://hex.pm/packages/phoenix_integration)
[![Hex Docs](https://img.shields.io/badge/hex-docs-lightgreen.svg)](https://hexdocs.pm/phoenix_integration/)
[![Total Download](https://img.shields.io/hexpm/dt/phoenix_integration.svg)](https://hex.pm/packages/phoenix_integration)
[![License](https://img.shields.io/hexpm/l/phoenix_integration.svg)](https://github.com/boydm/phoenix_integration/blob/master/LICENSE.md)
[![Last Updated](https://img.shields.io/github/last-commit/boydm/phoenix_integration.svg)](https://github.com/boydm/phoenix_integration/commits/master)

## Overview

`PhoenixIntegration` is set of lightweight, server-side integration test functions for Phoenix.
Works within the existing `Phoenix.ConnTest` framework and emphasizes both speed and readability.

The goal is to chain together a string of requests and assertions that thoroughly
exercise your application in as lightweight and readable manner as possible.

I love the pipe `|>` command in Elixir. By using the pipe to chain together calls in an integration test, `PhoenixIntegration` is able to be very readable. Tight integration with `Phoenix.ConnTest` means the calls all use the fast-path to your application for speed.

Version 0.6 moves from Poison to Jason for Phoenix 1.4 compatibility.

Version 0.7 requires Floki 0.24.0 or higher. Otherwise it is a patch-like update.

## Documentation

You can read [the full documentation here](https://hexdocs.pm/phoenix_integration).

## Configuration

### Step 1

You need to tell phoenix_integration which endpoint to use. Add the following to your phoenix application's `config/test.exs` file.

```elixir
config :phoenix_integration,
  endpoint: MyApp.Endpoint
```

Where MyApp is the name of your application.

Do this up before compiling phoenix_integration as part of step 2. If you change the endpoint in the config file, you will need to recompile the phoenix_integration dependency.

Phoenix_integration will produce warnings if your HTML likely doesn't do what you meant. (For example, it will warn you if two text fields have the same name.) You can turn those off by adding `warnings: false` to the config.


### Step 2

Add PhoenixIntegration to the deps section of your application's `mix.exs` file

```elixir
defp deps do
  [
    # ...
    {:phoenix_integration, "~> 0.9", only: :test}
    # ...
  ]
end
```

Don't forget to run `mix deps.get`

### Step 3

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

### Step 4
Start writing integration tests. They should use your integration_conn.ex file. Here is a full example (just the name of the app is changed). This is from the location test/integration/page_integration_test.exs

```elixir
defmodule MyApp.AboutIntegrationTest do
  use MyApp.IntegrationCase, async: true

  test "Basic page flow", %{conn: conn} do
    # get the root index page
    get( conn, page_path(conn, :index) )
    # click/follow through the various about pages
    |> follow_link( "About Us" )
    |> follow_link( "Contact" )
    |> follow_link( "Privacy" )
    |> follow_link( "Terms of Service" )
    |> follow_button( "Accept" )
    |> follow_link( "Home" )
    |> assert_response( status: 200, path: page_path(conn, :index) )
  end

end
```

Each function in phoenix_integration accepts a conn and some other data, and returns a conn. This conn is intended to be passed into the next function via a pipe to build up a clear, readable chain of events in your test.


## Making Requests

The [`PhoenixIntegration.Requests`](https://hexdocs.pm/phoenix_integration/PhoenixIntegration.Requests.html) module contains a set functions that make requests to your application through the router.

In general, these functions look for links or forms in the html returned by a previous request. Then they make a new request to application as specified by your test. If the link wasn’t found, then an appropriate error is raised.

See [the full documentation](https://hexdocs.pm/phoenix_integration/PhoenixIntegration.Requests.html) for details.

For example, a call such as `follow_link( conn, "About Us" )`, looks in conn.body_request (which should contain html from a previous request), for an anchor tag that contains the visible text ‘About Us’. Note that it uses =~ and not == to look for the text, so you only need to specify enough text to find the link.

These functions are also pretty flexible. A call such as `follow_link( conn, "/about/us" )` recognizes that this is a path, so it looks for an anchor tag with an href equal to `“/about/us”`. Similarly, you could pass in a css-style id such as `“#about_us”` to find an anchor with the specified html id.

### Handling Redirects

All functions of the form follow_* make a request to your app. Then if a redirect is returned, makes another request following the redirect. This will go on until max_redirects is reached.

The goal is that (similar to Capybara), your integration test code looks like a set of actions that a user would actually do. To a user, redirects just happen. Clicking links and following forms are what is important.

### Submitting Forms

The `follow_form` function finds a form in the body of the previously returned conn, fills in the fields you have specified (raising an appropriate error if the form or fields aren’t found), submits the form to your application, and follows any redirects.

Used in a integration pipe chain, it looks like this:

```elixir
test "Create new user", %{conn: conn} do
  # get the root index page
  get( conn, page_path(conn, :index) )
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

The `submit_form` function is very similar, except that you handle any redirects yourself.

### Tracking multiple users

A very common scenario involves interactions between multiple users. The good news is that user state is returned in the conn from your controllers, so it is easy to track.

Is this example, I use a test_sign_in_user function (not shown), which uses token authentication so that I don’t have to pay the BCrypt price every time I run a test…

```elixir
test "admin can create a thing", %{conn: conn} do
  # create and sign in admin
  admin = test_insert_user permissions: @admin_perms
  admin_conn = test_sign_in_user(conn, admin)

  # create and sign in regular user
  user = test_insert_user
  user_conn = test_sign_in_user(conn, user)

  # admin create a new thing
  get( admin_conn, admin_path(conn, :index) )
  |> follow_link( "Create Thing" )
  |> follow_form( %{ thing: %{
        name: "New Thing"
      }} )
  |> assert_response(
      status: 200,
      path: admin_path(conn, :index),
      html: "New Thing" )

  # load the thing
  thing = Repo.get_by(Thing, name: "New Thing")
  assert thing

  # the user should be able to view the thing
  get( user_conn, page_path(conn, :index) )
  |> follow_link( thing.name )
  |> assert_response(
      status: 200,
      path: thing_path(conn, :show, thing),
      html: "New Thing"
    )
end
```

## Asserting Responses

I really wanted to see unbroken chains of piped call to make it really clear that this was a chain of events/state being tested.

The following line, which is very common in Phoenix.ConnTest controller tests works well, but doesn’t allow you to build that chain of commands.

`assert html_response(conn, 200) =~ “Some text”`

So, the `PhoenixIntegration.Assertions` module introduces two new functions, which can test multiple conditions in a single call, and always return the (unchanged) conn being tested.

See [the full documentation](https://hexdocs.pm/phoenix_integration/PhoenixIntegration.Assertions.html) for details.

I use assert_response at almost a 1:1 ratio with the various request calls, so my tests often look something like this:

```elixir
test "Basic page flow", %{conn: conn} do
# get the root index page
  get( conn, page_path(conn, :index) )
  # click/follow through the various about pages
  |> follow_link( "About Us" )
  |> assert_response( status: 200, path: about_path(conn, :index) )
  |> follow_link( "Contact" )
  |> assert_response( content_type: "text/html" )
  |> follow_link( "Privacy" )
  |> assert_response( html: "Privacy Policy" )
  |> follow_button( "Accept" )
  |> assert_response( html: "Privacy Policy" )
  |> follow_link( "Home" )
  |> assert_response( status: 200, path: page_path(conn, :index) )
end
```

To keep the chain clean and readable, each call to `assert_response` takes a conn, followed by a list of conditions to assert against. These conditions can appear multiple times in a single and will be called in the order specified.

```elixir
|> assert_response(
    status: 200,
    path:   page_path(conn, :index)
    html:   "Good Content",
    html:   "More Content"
  )
```

The `refute_response` function is very similar in form to `assert_response`, except that it refutes the given conditions. I find that it is used much less frequently, and usually prove that a response doesn’t have a specific piece of content.

```elixir
|> follow_link( "Show Thing" )
|> assert_response(
    status: 200,
    path:   thing_path(conn, :show, thing)
    html:   "Good Content"
  )
|> refute_response(
    body: "Bad Content"
  )
```

## Copyright and License

Copyright (c) 2016 Boyd Multerer

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at [http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
