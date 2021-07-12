defmodule SpandexTesla.MixProject do
  use Mix.Project

  def project do
    [
      app: :spandex_tesla,
      version: "1.2.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      description: "Tracing integration between tesla and spandex",
      package: package(),
      name: "SpandexTesla",
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      maintainers: ["Thiago Santos"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/thiamsantos/spandex_tesla"}
    ]
  end

  defp docs do
    [
      main: "SpandexTesla",
      source_url: "https://github.com/thiamsantos/spandex_tesla"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:spandex, "~> 3.0", optional: true},
      {:mox, "~> 0.5", only: :test},
      {:ex_doc, "~> 0.21.3", only: :dev, runtime: false}
    ]
  end
end
