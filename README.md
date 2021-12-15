# SpandexTesla

<!-- MDOC !-->

Tracing integration between [tesla](https://hex.pm/packages/tesla) and [spandex](https://hex.pm/packages/spandex).
It leverages telemetry to get the [tesla](https://hex.pm/packages/tesla) events and trace them with [spandex](https://hex.pm/packages/spandex).

[![Hex.pm Version](http://img.shields.io/hexpm/v/spandex_tesla.svg?style=flat)](https://hex.pm/packages/spandex_tesla)
[![CI](https://github.com/thiamsantos/spandex_tesla/workflows/CI/badge.svg?branch=master)](https://github.com/thiamsantos/spandex_tesla/actions?query=branch%3Amaster)
[![Coverage Status](https://coveralls.io/repos/github/thiamsantos/spandex_tesla/badge.svg?branch=master)](https://coveralls.io/github/thiamsantos/spandex_tesla?branch=master)

## Installation

The package can be installed
by adding `spandex_tesla` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spandex_tesla, "~> 1.5.0"}
  ]
end
```

[Checkout the documentation](https://hexdocs.pm/spandex_tesla) for more information.

## Usage

Configure the correct tracer to be used:

```elixir
config :spandex_tesla
  service: :tesla, # Optional
  tracer: MyApp.Tracer, # Required
```

Include the [telemetry middleware](https://hexdocs.pm/tesla/Tesla.Middleware.Telemetry.html#content) in your tesla client:

```elixir
defmodule MyClient do
  use Tesla

  plug Tesla.Middleware.Telemetry

end
```

Attach the telemetry handler:

```elixir
# in application.ex
SpandexTesla.Telemetry.attach()
```

The docs can
be found at [https://hexdocs.pm/spandex_tesla](https://hexdocs.pm/spandex_tesla).

## Resource grouping

You can pass a custom resource callback to `SpandexTesla.Telemetry.attach/1` with `:resource` key in the config. If none provided, resource name will default to `<METHOD> <REQ_URL>`.

The resource callback takes telemetry event metadata (map) as parameter and returns a string resource name.

See [Tesla.Middleware.Telemetry](https://hexdocs.pm/tesla/Tesla.Middleware.Telemetry.html#module-telemetry-events) for metadata structure, and also usage of middleware for URL event scoping.

```elixir
SpandexTesla.Telemetry.attach(
  resource: fn %{env: %{url: url, method: method}} ->
    upcased_method = method |> to_string() |> String.upcase()
    "#{upcased_method} #{Regex.replace(~r/item\/(\d+$)/, url, "item/:item_id")}"
  end
)
```

## Changelog

See the [changelog](CHANGELOG.md).

<!-- MDOC !-->

## Contributing

See the [contributing file](CONTRIBUTING.md).

## License

Copyright 2021 (c) Thiago Santos.

spandex_tesla source code is released under Apache 2 License.

Check [LICENSE](https://github.com/thiamsantos/spandex_tesla/blob/master/LICENSE) file for more information.
