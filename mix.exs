defmodule SpandexTesla.MixProject do
  use Mix.Project

  @name "SpandexTesla"
  @version "1.5.1"
  @description "Tracing integration between tesla and spandex"
  @repo_url "https://github.com/thiamsantos/spandex_tesla"

  def project do
    [
      app: :spandex_tesla,
      version: @version,
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      name: @name,
      description: @description,
      deps: deps(),
      docs: docs(),
      package: package(),
      test_coverage: [tool: ExCoveralls]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp package do
    %{
      licenses: ["Apache-2.0"],
      maintainers: ["Thiago Santos"],
      links: %{"GitHub" => @repo_url}
    }
  end

  defp docs do
    [
      main: @name,
      source_ref: "v#{@version}",
      source_url: @repo_url,
      skip_undefined_reference_warnings_on: ["CHANGELOG.md"],
      extras: ["CHANGELOG.md"]
    ]
  end

  defp deps do
    [
      {:spandex, "~> 3.0", optional: true},

      # dev/test
      {:credo_naming, "~> 2.0", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.5", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:excoveralls, "~> 0.14.0", only: :test},
      {:mox, "~> 1.0", only: :test}
    ]
  end
end
