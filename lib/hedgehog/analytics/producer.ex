defmodule Hedgehog.Analytics.Producer do
  @moduledoc false
  @behaviour Broadway.Acknowledger
  @behaviour Broadway.Producer

  use GenStage

  def start_link(opts \\ []) do
    GenStage.start_link(__MODULE__, opts)
  end

  alias Broadway.Message
  alias Hedgehog.Analytics.Event
  alias Hedgehog.Config

  @impl true
  def init(_options) do
    :telemetry.attach(
      "hedgehog-analytics-producer-generic",
      [:hedgehog, :analytics, :event],
      &__MODULE__.handle_event/4,
      %{pid: self()}
    )

    if Config.get([:analytics, :pageview]) do
      :telemetry.attach(
        "hedgehog-analytics-producer-pageview",
        [:phoenix, :live_view, :mount, :stop],
        &__MODULE__.handle_event/4,
        %{pid: self()}
      )
    end

    {:producer, %{queue: :queue.new(), demand: 0}}
  end

  def handle_event([:hedgehog, :analytics, :event], _measurements, metadata, %{pid: pid}) do
    with event when not is_nil(event) <- Event.from_telemetry_event(metadata) do
      GenStage.cast(pid, {:push, event})
    end
  end

  def handle_event([:phoenix, :live_view, :mount, :stop], _measurements, metadata, %{pid: pid}) do
    with event when not is_nil(event) <- Event.pageview(metadata) do
      GenStage.cast(pid, {:push, event})
    end
  end

  @impl true
  def handle_cast({:push, event}, %{queue: queue, demand: demand} = state) when not is_nil(event) do
    queue = :queue.in(event, queue)
    dispatch_events(queue, demand, state)
  end

  @impl true
  def handle_demand(incoming_demand, %{queue: queue, demand: demand} = state) do
    dispatch_events(queue, incoming_demand + demand, state)
  end

  @impl true
  def ack(_ack_ref, _successful, failed) do
    Enum.each(failed, &requeue_failed_message/1)
    :ok
  end

  defp requeue_failed_message(message) do
    {_module, _ack_id, %{pid: pid}} = message.acknowledger
    GenStage.cast(pid, {:push, message.data})
  end

  defp dispatch_events(queue, demand, state) do
    {events, queue, pending_demand} = take_events_from_queue(queue, demand, [])
    messages = Enum.map(events, &%Message{data: &1, acknowledger: {__MODULE__, :ack_id, %{pid: self()}}})

    {:noreply, messages, %{state | queue: queue, demand: pending_demand}}
  end

  defp take_events_from_queue(queue, 0, events), do: {Enum.reverse(events), queue, 0}

  defp take_events_from_queue(queue, demand, events) do
    case :queue.out(queue) do
      {{:value, event}, updated_queue} ->
        take_events_from_queue(updated_queue, demand - 1, [event | events])

      {:empty, queue} ->
        {Enum.reverse(events), queue, demand}
    end
  end
end
