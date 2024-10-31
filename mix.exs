defmodule Hedgehog.MixProject do
  use Mix.Project

  def project do
    [
      app: :hedgehog,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:gen_stage, "~> 1.2"}
    ]
  end
end
