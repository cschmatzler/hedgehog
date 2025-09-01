defmodule Hedgehog.Analytics.Buffer do
  @moduledoc false

  use GenServer

  alias Hedgehog.Analytics.Event
  alias Hedgehog.Client
  alias Hedgehog.Config

  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def insert(server \\ __MODULE__, event) do
    GenServer.cast(server, {:insert, event})
  end

  def flush(server \\ __MODULE__) do
    GenServer.call(server, :flush, :infinity)
  end

  @impl true
  def init(_opts) do
    :telemetry.attach(
      "hedgehog-analytics-producer-generic",
      [:hedgehog, :analytics, :event],
      &__MODULE__.handle_telemetry_event/4,
      %{pid: self()}
    )

    if Config.get([:analytics, :pageview]) do
      if Code.ensure_loaded?(Config.get([:analytics, :user])) do
        :telemetry.attach(
          "hedgehog-analytics-producer-pageview",
          [:phoenix, :live_view, :mount, :stop],
          &__MODULE__.handle_telemetry_event/4,
          %{pid: self()}
        )
      else
        Logger.warning("Hedgehog: Tracking pageviews requires a valid user module to be configured.")
      end
    end

    buffer = []
    max_buffer_size = Config.get([:analytics, :batch_size], 500)
    flush_interval_ms = Config.get([:analytics, :batch_timeout], 10_000)

    Process.flag(:trap_exit, true)
    timer = Process.send_after(self(), :tick, flush_interval_ms)

    {:ok,
     %{
       buffer: buffer,
       timer: timer,
       buffer_size: 0,
       max_buffer_size: max_buffer_size,
       flush_interval_ms: flush_interval_ms
     }}
  end

  def handle_telemetry_event([:hedgehog, :analytics, :event], _measurements, metadata, %{pid: pid}) do
    with event when not is_nil(event) <- Event.from_telemetry_event(metadata) do
      GenServer.cast(pid, {:insert, event})
    end
  end

  def handle_telemetry_event([:phoenix, :live_view, :mount, :stop], _measurements, metadata, %{pid: pid}) do
    with event when not is_nil(event) <- Event.pageview(metadata) do
      GenServer.cast(pid, {:insert, event})
    end
  end

  @impl true
  def handle_cast({:insert, event}, state) do
    state = %{
      state
      | buffer: [event | state.buffer],
        buffer_size: state.buffer_size + 1
    }

    if state.buffer_size >= state.max_buffer_size do
      Logger.notice("Analytics buffer full, flushing to PostHog")
      Process.cancel_timer(state.timer)
      do_flush(state)
      new_timer = Process.send_after(self(), :tick, state.flush_interval_ms)
      {:noreply, %{state | buffer: [], timer: new_timer, buffer_size: 0}}
    else
      {:noreply, state}
    end
  end

  @impl true
  def handle_info(:tick, state) do
    do_flush(state)
    timer = Process.send_after(self(), :tick, state.flush_interval_ms)
    {:noreply, %{state | buffer: [], buffer_size: 0, timer: timer}}
  end

  @impl true
  def handle_call(:flush, _from, state) do
    %{timer: timer, flush_interval_ms: flush_interval_ms} = state
    Process.cancel_timer(timer)
    do_flush(state)
    new_timer = Process.send_after(self(), :tick, flush_interval_ms)
    {:reply, :ok, %{state | buffer: [], buffer_size: 0, timer: new_timer}}
  end

  @impl true
  def terminate(_reason, state) do
    Logger.notice("Flushing analytics buffer before shutdown...")
    do_flush(state)
  end

  defp do_flush(state) do
    %{
      buffer: buffer,
      buffer_size: buffer_size
    } = state

    case buffer do
      [] ->
        nil

      _not_empty ->
        Logger.notice("Flushing #{buffer_size} event(s) to PostHog")
        events = Enum.reverse(buffer)

        case Client.batch(events) do
          {:ok, %{status: status}} when status in 200..299 ->
            Logger.debug("Successfully flushed #{buffer_size} events")

          error ->
            Logger.error("Failed to flush events: #{inspect(error)}")
        end
    end
  end
end
