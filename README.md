# SpandexTesla


[![Build Status](https://github.com/thiamsantos/spandex_tesla/workflows/CI/badge.svg)](https://github.com/thiamsantos/spandex_tesla/actions)

Tracing integration between [tesla](https://hex.pm/packages/tesla) and [spandex](https://hex.pm/packages/spandex).
It leverages telemetry to get the [tesla](https://hex.pm/packages/tesla) events and trace them with [spandex](https://hex.pm/packages/spandex).

## Installation

The package can be installed
by adding `spandex_tesla` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:spandex_tesla, "~> 1.1.0"}
  ]
end
```

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
:telemetry.attach(
  "spandex-tesla-tracer",
  [:tesla, :request],
  &SpandexTesla.handle_event/4,
  nil
)
```

The docs can
be found at [https://hexdocs.pm/spandex_tesla](https://hexdocs.pm/spandex_tesla).


## License

[Apache License, Version 2.0](LICENSE) © [Thiago Santos](https://github.com/thiamsantos)
