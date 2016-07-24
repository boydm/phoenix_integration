defmodule PhoenixIntegration do

  @moduledoc """
  Lightweight integration test support for Phoenix. Extends the existing
  Phoenix.ConnTest framework.

  ## Overview

  Overview `"topic:subtopic"` goes here

    channel "room:*", MyApp.RoomChannel

  More stuff goes here


  ### Example
      test "Basic page flow", %{conn: conn} do
        # get the root index page
        get( conn, page_path(conn, :index) )

        # click/follow through the various about pages
        |> follow_link( conn, "About Us" )
        |> assert_response( status: 200, path: about_path(conn, :index) )
        |> follow_link( conn, "Contact" )
        |> assert_response( status: 200, path: about_path(conn, :contact) )
        |> follow_link( conn, "Privacy" )
        |> assert_response( status: 200, path: about_path(conn, :privacy) )
        |> follow_link( conn, "Terms of Service" )
        |> assert_response( status: 200, path: about_path(conn, :tos) )
        |> follow_link( conn, "Home" )
        |> assert_response( status: 200, path: page_path(conn, :index) )
      end

      test "Create new user, %{conn: conn} do
        # get the root index page
        get( conn, page_path(conn, :index) )

        # click/follow through the various about pages
        |> follow_link( conn, "Sign Up" )
        |> assert_response( status: 200, path: user_path(conn, :new) )
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

  
  """

  defmacro __using__(_opts) do
    quote do
      import PhoenixIntegration.Assertions
      import PhoenixIntegration.Requests
    end # quote
  end # defmacro


end
