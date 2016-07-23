use Mix.Config

  case Mix.env do
    :test ->
      config :phoenix, :template_engines,
        md: PhoenixMarkdown.Engine

      # Configures the endpoint
      config :phoenix_integration, PhoenixIntegration.TestSupport.Requests.Endpoint,
        url: [host: "localhost"],
        secret_key_base: "SomeSecretKeyGoesHereThisIsJustForTest"

      config :phoenix_integration,
        endpoint: PhoenixIntegration.TestSupport.Requests.Endpoint

    _ -> nil
  end
