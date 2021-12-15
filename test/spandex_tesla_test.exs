defmodule SpandexTeslaTest do
  use ExUnit.Case, async: true
  import Mox
  alias SpandexTesla.ClockMock
  alias SpandexTesla.TracerMock

  setup :verify_on_exit!

  describe "handle_event/4 with new telemetry events" do
    test "skip span when there is no trace_id" do
      duration = 1_000

      expect(TracerMock, :current_trace_id, 2, fn _ -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request, :start],
        nil,
        nil,
        []
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{env: %{status: 200, url: "https://google.com", method: :get, opts: []}},
        []
      )
    end

    test "span tesla request success result" do
      now = System.system_time()
      duration = 1_000
      trace_id = "trace_id"
      span_id = "span_id"

      ClockMock
      |> expect(:system_time, fn -> now end)

      TracerMock
      |> expect(:current_trace_id, 3, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:update_span, fn opts ->
        assert opts[:start] == now - duration
        assert opts[:completion_time] == now
        assert opts[:service] == :tesla
        assert opts[:resource] == "GET https://google.com"
        assert opts[:type] == :web
        assert opts[:http] == [url: "https://google.com", status_code: 200, method: "GET"]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request, :start],
        nil,
        nil,
        []
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{env: %{status: 200, url: "https://google.com", method: :get, opts: []}},
        []
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with req_url" do
      now = System.system_time()
      duration = 1_000
      trace_id = "trace_id"
      span_id = "span_id"

      ClockMock
      |> expect(:system_time, fn -> now end)

      TracerMock
      |> expect(:current_trace_id, 3, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:update_span, fn opts ->
        assert opts[:start] == now - duration
        assert opts[:completion_time] == now
        assert opts[:service] == :tesla
        assert opts[:resource] == "GET https://google.com/item/:item_id"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com/item/555",
                 status_code: 200,
                 method: "GET"
               ]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request, :start],
        nil,
        nil,
        []
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{
          env: %{
            status: 200,
            url: "https://google.com/item/555",
            method: :get,
            opts: [req_url: "https://google.com/item/:item_id"]
          }
        },
        []
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with custom resource function" do
      now = System.system_time()
      duration = 1_000
      trace_id = "trace_id"
      span_id = "span_id"

      ClockMock
      |> expect(:system_time, fn -> now end)

      TracerMock
      |> expect(:current_trace_id, 3, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:update_span, fn opts ->
        assert opts[:start] == now - duration
        assert opts[:completion_time] == now
        assert opts[:service] == :tesla
        assert opts[:resource] == "GET https://google.com/item/:item_id"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com/item/555",
                 status_code: 200,
                 method: "GET"
               ]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request, :start],
        nil,
        nil,
        resource: &resource_name/1
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{env: %{status: 200, url: "https://google.com/item/555", method: :get, opts: []}},
        resource: &resource_name/1
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request with error on result metadata" do
      now = System.system_time()
      duration = 1_000
      trace_id = "trace_id"
      span_id = "span_id"

      ClockMock
      |> expect(:system_time, fn -> now end)

      TracerMock
      |> expect(:current_trace_id, 2, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:span_error, fn error, nil, opts ->
        assert error == %SpandexTesla.Error{message: "timeout"}
        assert opts[:start] == now - duration
        assert opts[:completion_time] == now
        assert opts[:service] == :tesla
        assert opts[:resource] == "GET https://google.com/item/:item_id"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com/item/555",
                 status_code: nil,
                 method: "GET"
               ]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request, :start],
        nil,
        nil,
        resource: &resource_name/1
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{
          env: %{
            url: "https://google.com/item/555",
            method: :get,
            status: nil,
            opts: []
          },
          error: :timeout
        },
        resource: &resource_name/1
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request with status code different from 2xx should sent error to spandex" do
      now = System.system_time()
      duration = 1_000
      trace_id = "trace_id"
      span_id = "span_id"

      status_code_response = 404
      error_expected = "Request has failed with status response #{status_code_response}"

      ClockMock
      |> expect(:system_time, fn -> now end)

      TracerMock
      |> expect(:current_trace_id, 3, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:span_error, fn error, nil, opts ->
        assert error == %SpandexTesla.Error{message: error_expected}
        assert opts[:start] == now - duration
        assert opts[:completion_time] == now
        assert opts[:service] == :tesla
        assert opts[:resource] == "GET https://google.com/item/:item_id"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com/item/555",
                 status_code: status_code_response,
                 method: "GET"
               ]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request, :start],
        nil,
        nil,
        resource: &resource_name/1
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{
          env: %{
            status: status_code_response,
            url: "https://google.com/item/555",
            method: :get,
            opts: []
          }
        },
        resource: &resource_name/1
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request error result" do
      trace_id = "trace_id"
      span_id = "span_id"

      TracerMock
      |> expect(:current_trace_id, 2, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:span_error, fn error, nil, [] ->
        assert error == %SpandexTesla.Error{message: inspect(:timeout)}
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request, :exception],
        %{duration: 1_000},
        %{reason: :timeout},
        []
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end
  end

  describe "handle_event/4 with legacy telemetry events" do
    test "skip span when there is no trace_id" do
      expect(TracerMock, :current_trace_id, fn _ -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request],
        %{request_time: 1_000},
        %{result: {:ok, %{status: 200, url: "https://google.com", method: :get, opts: []}}},
        []
      )
    end

    test "span tesla request success result" do
      now = System.system_time()
      request_time = 1_000
      trace_id = "trace_id"
      span_id = "span_id"

      ClockMock
      |> expect(:system_time, fn -> now end)

      TracerMock
      |> expect(:current_trace_id, 2, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:update_span, fn opts ->
        assert opts[:start] ==
                 now - System.convert_time_unit(request_time, :microsecond, :nanosecond)

        assert opts[:completion_time] == now
        assert opts[:service] == :tesla
        assert opts[:resource] == "GET https://google.com"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com",
                 status_code: 200,
                 method: "GET"
               ]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request],
        %{request_time: request_time},
        %{result: {:ok, %{status: 200, url: "https://google.com", method: :get, opts: []}}},
        []
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with req_url" do
      now = System.system_time()
      request_time = 1_000
      trace_id = "trace_id"
      span_id = "span_id"

      ClockMock
      |> expect(:system_time, fn -> now end)

      TracerMock
      |> expect(:current_trace_id, 2, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:update_span, fn opts ->
        assert opts[:start] ==
                 now - System.convert_time_unit(request_time, :microsecond, :nanosecond)

        assert opts[:completion_time] == now
        assert opts[:service] == :tesla
        assert opts[:resource] == "GET https://google.com/item/:item_id"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com/item/555",
                 status_code: 200,
                 method: "GET"
               ]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request],
        %{request_time: request_time},
        %{
          result:
            {:ok,
             %{
               status: 200,
               url: "https://google.com/item/555",
               method: :get,
               opts: [req_url: "https://google.com/item/:item_id"]
             }}
        },
        []
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with custom resource function" do
      now = System.system_time()
      request_time = 1_000
      trace_id = "trace_id"
      span_id = "span_id"

      ClockMock
      |> expect(:system_time, fn -> now end)

      TracerMock
      |> expect(:current_trace_id, 2, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:update_span, fn opts ->
        assert opts[:start] ==
                 now - System.convert_time_unit(request_time, :microsecond, :nanosecond)

        assert opts[:completion_time] == now
        assert opts[:service] == :tesla
        assert opts[:resource] == "GET https://google.com/item/:item_id"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com/item/555",
                 status_code: 200,
                 method: "GET"
               ]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request],
        %{request_time: request_time},
        %{
          result:
            {:ok, %{status: 200, url: "https://google.com/item/555", method: :get, opts: []}}
        },
        resource: &resource_name/1
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request error result" do
      trace_id = "trace_id"
      span_id = "span_id"

      ClockMock
      |> expect(:system_time, fn -> System.system_time() end)

      TracerMock
      |> expect(:current_trace_id, 2, fn [] -> trace_id end)
      |> expect(:current_span_id, fn [] -> span_id end)
      |> expect(:start_span, fn "request", [] -> nil end)
      |> expect(:span_error, fn error, nil, [] ->
        assert error == %SpandexTesla.Error{message: inspect(:timeout)}
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request],
        %{request_time: 1_000},
        %{result: {:error, :timeout}},
        []
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end
  end

  defp resource_name(%{env: %{url: url, method: method}}) do
    upcased_method = method |> to_string() |> String.upcase()
    "#{upcased_method} #{Regex.replace(~r/item\/(\d+$)/, url, "item/:item_id")}"
  end

  defp resource_name(%{result: {:ok, %{method: method, url: url}}}) do
    upcased_method = method |> to_string() |> String.upcase()
    "#{upcased_method} #{Regex.replace(~r/item\/(\d+$)/, url, "item/:item_id")}"
  end
end
