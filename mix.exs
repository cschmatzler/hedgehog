defmodule Hedgehog.MixProject do
  use Mix.Project

  def project do
    [
      app: :hedgehog,
      description: "A Posthog SDK with extra spines",
      version: "0.0.1",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:broadway, "~> 1.1"},
      {:gen_stage, "~> 1.2"},
      {:jason, "~> 1.4"},
      {:req, "~> 0.5"},
      {:nimble_options, "~> 1.1"},
      {:phoenix_live_view, "~> 1.0.0-rc.7"},
      {:plug, "~> 1.16"},
      {:styler, "~> 1.1", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "hedgehog",
      licenses: ["MIT"],
      maintainers: ["Christoph Schmatzler"],
      links: %{"GitHub" => "https://github.com/cschmatzler/hedgehog"}
    ]
  end

  defp docs do
    [
      main: "Hedgehog",
      formatters: ["html"],
      extras: ["CHANGELOG.md"] ++ Path.wildcard("guides/**"),
      groups_for_extras: [
        Guides: Path.wildcard("guides/**")
      ]
    ]
  end
end
