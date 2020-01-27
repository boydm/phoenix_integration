use Mix.Config

case Mix.env() do
  :test ->
    config :phoenix, :template_engines, md: PhoenixMarkdown.Engine

    config :phoenix_integration,
      endpoint: PhoenixIntegration.TestEndpoint

  _ ->
    nil
end
