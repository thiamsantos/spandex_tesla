defmodule SpandexTesla do
  @moduledoc """
  Tracing integration between [tesla](https://hex.pm/packages/tesla) and [spandex](https://hex.pm/packages/spandex).
  It leverages telemetry to get the [tesla](https://hex.pm/packages/tesla) events and trace them with [spandex](https://hex.pm/packages/spandex).

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

  """

  defmodule Error do
    @moduledoc """
    Struct used to identify the errors.
    """
    defexception [:message]
  end

  @doc """
  Telemetry handler. Attach it to the telemetry tesla events in order to trace the tesla calls.
  """
  def handle_event([:tesla, :request, :start], _measurements, _metadata, _config) do
    if tracer().current_trace_id([]) do
      tracer().start_span("request", [])

      Logger.metadata(
        trace_id: to_string(tracer().current_trace_id([])),
        span_id: to_string(tracer().current_span_id([]))
      )
    end
  end

  def handle_event([:tesla, :request, :stop], measurements, metadata, config) do
    if tracer().current_trace_id([]) do
      now = clock_adapter().system_time()
      %{duration: duration} = measurements
      %{status: status, url: url, method: method} = metadata[:env]

      update_span(
        %{duration: duration, method: method, now: now, status: status, url: url},
        metadata,
        config || []
      )

      tracer().finish_span([])
    end
  end

  def handle_event([:tesla, :request, :exception], _measurements, metadata, _config) do
    if tracer().current_trace_id([]) do
      reason = metadata[:reason] || metadata[:error]

      tracer().span_error(%Error{message: inspect(reason)}, nil, [])

      tracer().finish_span([])

      Logger.metadata(
        trace_id: to_string(tracer().current_trace_id([])),
        span_id: to_string(tracer().current_span_id([]))
      )
    end
  end

  def handle_event([:tesla, :request], measurements, metadata, config) do
    if tracer().current_trace_id([]) do
      now = clock_adapter().system_time() |> System.convert_time_unit(:native, :nanosecond)
      %{request_time: request_time} = measurements
      %{result: result} = metadata

      tracer().start_span("request", [])

      Logger.metadata(
        trace_id: to_string(tracer().current_trace_id([])),
        span_id: to_string(tracer().current_span_id([]))
      )

      span_result(result, %{request_time: request_time, now: now}, metadata, config || [])

      tracer().finish_span([])
    end
  end

  defp span_result({:ok, request}, measurements, metadata, config) do
    %{request_time: request_time, now: now} = measurements
    %{status: status, url: url, method: method} = request

    duration = System.convert_time_unit(request_time, :microsecond, :nanosecond)

    update_span(
      %{duration: duration, method: method, now: now, status: status, url: url},
      metadata,
      config
    )
  end

  defp span_result({:error, reason}, _measurements, _metadata, _config) do
    tracer().span_error(%Error{message: inspect(reason)}, nil, [])
  end

  defp update_span(
         %{duration: duration, method: method, now: now, status: status, url: url},
         metadata,
         config
       ) do
    upcased_method = method |> to_string() |> String.upcase()

    tracer().update_span(
      start: now - duration,
      completion_time: now,
      service: service(),
      resource: resource_name(metadata, config),
      type: :web,
      http: [
        url: url,
        status_code: status,
        method: upcased_method
      ]
    )
  end

  defp resource_name(metadata, config) do
    get_resource_name = Keyword.get(config, :resource, &default_resource_name/1)

    get_resource_name.(metadata)
  end

  defp default_resource_name(%{env: %{url: url, method: method}}) do
    upcased_method = method |> to_string() |> String.upcase()
    "#{upcased_method} #{url}"
  end

  defp default_resource_name(%{result: {:ok, %{method: method, url: url}}}) do
    upcased_method = method |> to_string() |> String.upcase()
    "#{upcased_method} #{url}"
  end

  defp tracer do
    Application.fetch_env!(:spandex_tesla, :tracer)
  end

  defp service do
    Application.get_env(:spandex_tesla, :service, :tesla)
  end

  defp clock_adapter do
    Application.get_env(:spandex_tesla, :clock_adapter, System)
  end
end
