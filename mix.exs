defmodule PhoenixIntegration.Mixfile do
  use Mix.Project

  def project do
    [
      app: :phoenix_integration,
      version: "0.0.1",
      elixir: "~> 1.1",
      elixirc_paths: elixirc_paths(Mix.env),
      deps: deps(),
      package: [
        contributors: ["Boyd Multerer"],
        maintainers: ["Boyd Multerer"],
        licenses: ["MIT"],
        links: %{github: "https://github.com/boydm/phoenix_integration"}
      ],
      name: "phoenix_integration",
      source_url: "https://github.com/boydm/phoenix_integration",

      description: """
      Phoenix server-side integration test tools. Very lightweight. Meant to be used
      with and alongside Phoenix.ConnCase and other tools.
      """
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_),     do: ["lib"]


  def application do
    [applications: [:phoenix]]
  end

  defp deps do
    [
      {:phoenix, "~> 1.1"},
      {:phoenix_html, "~> 2.3"},
      {:floki, "~> 0.9"},             # html parser

     # Docs dependencies
     {:ex_doc, "~> 0.13", only: :dev},
     {:inch_ex, "~> 0.5", only: :dev}
    ]
  end

#  defp docs do
#    extras: ["README.md"]
#  end
end
