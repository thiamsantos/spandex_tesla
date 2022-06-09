defmodule SpandexTesla do
  @external_resource "README.md"
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

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

  def handle_event(
        [:tesla, :request, :stop],
        measurements,
        %{error: error, env: env} = metadata,
        config
      ) do
    now = clock_adapter().system_time()
    %{duration: duration} = measurements
    %{url: url, method: method} = env

    trace_opts =
      format_trace_options(
        %{duration: duration, status: nil, method: method, now: now, url: url},
        metadata,
        config || []
      )

    tracer().span_error(
      %Error{message: span_error_message(error)},
      nil,
      trace_opts
    )

    tracer().finish_span([])
  end

  def handle_event([:tesla, :request, :stop], measurements, metadata, config) do
    if tracer().current_trace_id([]) do
      now = clock_adapter().system_time()
      %{duration: duration} = measurements
      %{status: status, url: url, method: method} = metadata[:env]

      trace_opts =
        format_trace_options(
          %{duration: duration, method: method, now: now, status: status, url: url},
          metadata,
          config || []
        )

      case status do
        x when x not in 200..299 ->
          tracer().span_error(
            %Error{message: "Request has failed with status response #{status}"},
            nil,
            trace_opts
          )

        _ ->
          tracer().update_span(trace_opts)
      end

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

    trace_opts =
      format_trace_options(
        %{duration: duration, method: method, now: now, status: status, url: url},
        metadata,
        config
      )

    tracer().update_span(trace_opts)
  end

  defp span_result({:error, reason}, _measurements, _metadata, _config) do
    tracer().span_error(%Error{message: inspect(reason)}, nil, [])
  end

  defp format_trace_options(
         %{duration: duration, method: method, now: now, status: status, url: url},
         metadata,
         config
       ) do
    upcased_method = method |> to_string() |> String.upcase()

    [
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
    ]
  end

  defp resource_name(metadata, config) do
    get_resource_name = Keyword.get(config, :resource, &default_resource_name/1)

    get_resource_name.(metadata)
  end

  defp default_resource_name(%{env: %{url: url, method: method, opts: opts}}) do
    upcased_method = method |> to_string() |> String.upcase()
    resource_url = Keyword.get(opts, :req_url, url)

    "#{upcased_method} #{resource_url}"
  end

  defp default_resource_name(%{result: {:ok, %{method: method, url: url, opts: opts}}}) do
    upcased_method = method |> to_string() |> String.upcase()
    resource_url = Keyword.get(opts, :req_url, url)

    "#{upcased_method} #{resource_url}"
  end

  defp span_error_message(error) when is_binary(error), do: error
  defp span_error_message(error) when is_atom(error), do: to_string(error)
  defp span_error_message(error), do: inspect(error)

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
