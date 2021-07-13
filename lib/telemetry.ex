defmodule SpandexTesla.Telemetry do
  @moduledoc """
  Defines the `:telemetry` handlers to attach tracing to Tesla Telemetry.
  """

  @type method :: String.t()
  @type pattern :: Regex.t()
  @type group :: String.t() | fun()

  @typedoc ~s(Example: `{"GET", ~r"^https://google.com/item/\\d+", "https://google.com/item/<id>"}`)
  @type resource_group :: {method, pattern, group}

  @type resource_groups :: [resource_group]

  @type config :: [{:resource_groups, resource_groups}]

  @doc """
  Automatic installer. Call it from application.ex to trace all events generated by Tesla.
  """
  @spec attach(config) :: :ok
  def attach(config \\ []) do
    if new_telemetry_events_supported?() do
      tesla_events = [
        [:tesla, :request, :start],
        [:tesla, :request, :stop],
        [:tesla, :request, :exception]
      ]

      :telemetry.attach_many(__MODULE__, tesla_events, &SpandexTesla.handle_event/4, config)
    else
      :telemetry.attach(__MODULE__, [:tesla, :request], &SpandexTesla.handle_event/4, config)
    end
  end

  defp new_telemetry_events_supported? do
    case :application.get_key(:tesla, :vsn) do
      {:ok, version} ->
        version
        |> List.to_string()
        |> Version.match?(">= 1.3.3")

      _ ->
        false
    end
  end
end
