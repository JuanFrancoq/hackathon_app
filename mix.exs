defmodule HackathonApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :hackathon_app,
      version: "0.1.0",
      elixir: "~> 1.18",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {HackathonApp, []}
    ]
  end

  defp deps do
    [
      # dependencias aquí si más adelante usas
    ]
  end
end
