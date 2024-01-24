defmodule AbsintheRelayDataloader.MixProject do
  use Mix.Project

  def project do
    [
      app: :absinthe_relay_dataloader,
      version: "0.0.1",
      elixir: "~> 1.16",
      elixirc_paths: elixirc_paths(Mix.env()),
      aliases: aliases(),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:absinthe, "~> 1.5.0 or ~> 1.6.0 or ~> 1.7.0"},
      {:absinthe_relay, "~> 1.5"},
      {:ecto, "~> 2.0 or ~> 3.0"},
      {:dataloader, "~> 1.0 or ~> 2.0"},
      {:ecto_sql, "~> 3.0"},
      {:postgrex, "~> 0.14", only: :test, runtime: false},
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"]
    ]
  end
end
