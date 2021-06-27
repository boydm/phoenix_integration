defmodule PhoenixIntegration.Mixfile do
  use Mix.Project

  @source_url "https://github.com/boydm/phoenix_integration"
  @version "0.9.2"

  def project do
    [
      app: :phoenix_integration,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: "phoenix_integration",
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  def application do
    [applications: [:phoenix, :floki, :jason]]
  end

  defp deps do
    [
      {:phoenix, "~> 1.3"},
      {:phoenix_html, "~> 2.10 or ~> 3.0"},
      {:floki, ">= 0.24.0"},
      {:jason, "~> 1.1"},
      {:flow_assertions, "~> 0.7", only: :test},
      {:ex_doc, ">= 0.0.0", only: [:dev, :docs]},
      {:inch_ex, ">= 0.0.0", only: :docs}
    ]
  end

  def docs do
    [
      extras: [
        "CHANGELOG.md": [title: "Changelog"],
        "LICENSE.md": [title: "License"],
        "README.md": [title: "Overview"]
      ],
      main: "readme",
      source_url: @source_url,
      source_ref: "v#{@version}",
      formatters: ["html"]
    ]
  end

  defp package do
    [
      description:
        "Lightweight server-side integration test functions for Phoenix." <>
          " Optimized for Elixir Pipes and the existing Phoenix.ConnTest" <>
          " framework to emphasize both speed and readability.",
      contributors: ["Boyd Multerer"],
      maintainers: ["Boyd Multerer"],
      licenses: ["Apache-2.0"],
      links: %{
        "Changelog" => "https://hexdocs.pm/phoenix_integration/changelog.html",
        "Blog Post" =>
          "https://medium.com/@boydm/integration-testing-phoenix-applications-b2a46acae9cb",
        "GitHub" => @source_url
      }
    ]
  end
end
