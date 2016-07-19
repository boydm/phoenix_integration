defmodule PhoenixIntegration.Mixfile do
  use Mix.Project

  def project do
    [
      app: :phoenix_integration,
      version: "0.0.1",
      elixir: "~> 1.1",
      deps: deps(),
      package: [
        contributors: ["Boyd Multerer"],
        maintainers: ["Boyd Multerer"],
        licenses: ["MIT"],
        links: %{github: "https://github.com/boydm/phoenix_integration"}
      ],
      description: """
      Phoenix server-side integration test tools. Very lightweight. Meant to be used
      with and alongside Phoenix.ConnCase and other tools.
      """
    ]
  end

  def application do
    [applications: [:phoenix]]
  end

  defp deps do
    [{:phoenix, "~> 1.1"}]
  end
end
