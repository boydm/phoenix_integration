use Mix.Config

  case Mix.env do
    :test ->
      config :phoenix, :template_engines,
        md: PhoenixMarkdown.Engine
    _ -> nil
  end
