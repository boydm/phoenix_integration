defmodule PhoenixIntegration.Mixfile do
  use Mix.Project

  @version "0.9.2"
  @url "https://github.com/boydm/phoenix_integration"

  def project do
    [
      app: :phoenix_integration,
      version: @version,
      elixir: "~> 1.10",
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      package: [
        contributors: ["Boyd Multerer"],
        maintainers: ["Boyd Multerer"],
        licenses: ["MIT"],
        links: %{
          "GitHub" => @url,
          "Blog Post" =>
            "https://medium.com/@boydm/integration-testing-phoenix-applications-b2a46acae9cb"
        }
      ],
      name: "phoenix_integration",
      source_url: @url,
      docs: docs(),
      description: """
      Lightweight server-side integration test functions for Phoenix.
      Optimized for Elixir Pipes and the existing Phoenix.ConnTest
      framework to emphasize both speed and readability.
      """
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
      {:floki, ">= 0.24.0"},
      {:jason, "~> 1.1"},
      {:flow_assertions, "~> 0.7", only: :test},

      # Docs dependencies
      {:ex_doc, ">= 0.0.0", only: [:dev, :docs]},
      {:inch_ex, ">= 0.0.0", only: :docs}
      # {:credo, "~> 1.0", only: [:dev, :test], runtime: false}
    ]
  end

  def docs do
    [
      extras: ["README.md"],
      source_ref: "v#{@version}",
      main: "PhoenixIntegration"
    ]
  end
end
