defmodule SpandexTeslaTest do
  use ExUnit.Case, async: true
  import Mox
  alias SpandexTesla.{ClockMock, TracerMock}

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
        %{env: %{status: 200, url: "https://google.com", method: :get}},
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
        %{env: %{status: 200, url: "https://google.com", method: :get}},
        []
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with matching resource group string" do
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
        assert opts[:resource] == "GET https://google.com/item/<item-id>"
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
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+", "https://google.com/item/<item-id>"}
        ]
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{env: %{status: 200, url: "https://google.com/item/555", method: :get}},
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+", "https://google.com/item/<item-id>"}
        ]
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with matching resource group function" do
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
        assert opts[:resource] == "GET https://google.com/item/***"
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
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+", "https://google.com/item/<item-id>"}
        ]
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{env: %{status: 200, url: "https://google.com/item/555", method: :get}},
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+",
           fn method, url -> "#{method} #{Regex.replace(~r/\d/, url, "*")}" end}
        ]
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with no matching resource group" do
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
        assert opts[:resource] == "GET https://google.com/another-endpoint/555"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com/another-endpoint/555",
                 status_code: 200,
                 method: "GET"
               ]
      end)
      |> expect(:finish_span, fn [] -> nil end)

      SpandexTesla.handle_event(
        [:tesla, :request, :start],
        nil,
        nil,
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+", "https://google.com/item/<item-id>"}
        ]
      )

      SpandexTesla.handle_event(
        [:tesla, :request, :stop],
        %{duration: duration},
        %{env: %{status: 200, url: "https://google.com/another-endpoint/555", method: :get}},
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+", "https://google.com/item/<item-id>"}
        ]
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
        %{result: {:ok, %{status: 200, url: "https://google.com", method: :get}}},
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
        %{result: {:ok, %{status: 200, url: "https://google.com", method: :get}}},
        []
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with matching resource group string" do
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
        assert opts[:resource] == "GET https://google.com/item/<item-id>"
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
        %{result: {:ok, %{status: 200, url: "https://google.com/item/555", method: :get}}},
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+", "https://google.com/item/<item-id>"}
        ]
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with matching resource group function" do
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
        assert opts[:resource] == "GET https://google.com/item/***"
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
        %{result: {:ok, %{status: 200, url: "https://google.com/item/555", method: :get}}},
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+",
           fn method, url -> "#{method} #{Regex.replace(~r/\d/, url, "*")}" end}
        ]
      )

      assert Logger.metadata() == [span_id: "span_id", trace_id: "trace_id"]
    end

    test "span tesla request success result with no matching resource group" do
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
        assert opts[:resource] == "GET https://google.com/another-endpoint/555"
        assert opts[:type] == :web

        assert opts[:http] == [
                 url: "https://google.com/another-endpoint/555",
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
            {:ok, %{status: 200, url: "https://google.com/another-endpoint/555", method: :get}}
        },
        resource_groups: [
          {"GET", ~r"https://google.com/item/\d+", "https://google.com/item/<item-id>"}
        ]
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
end
