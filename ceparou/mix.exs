defmodule Ceparou.MixProject do
  use Mix.Project

  def project do
    [
      app: :ceparou,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :mongodb_driver, :cachex],
      mod: {Ceparou.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:jason, "~> 1.1"},
      {:plug_cowboy, "~> 2.0"},
      {:mongodb_driver, "~> 0.6"},
      {:cachex, "~> 3.2"}
    ]
  end
end
