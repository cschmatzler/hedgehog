defmodule Hedgehog.Analytics.Producer do
  @moduledoc false
  @behaviour Broadway.Acknowledger
  @behaviour Broadway.Producer

  use GenStage

  alias Broadway.Message
  alias Hedgehog.Analytics.Event

  @impl true
  def init(_options) do
    :telemetry.attach(
      "hedgehog-analytics-producer",
      [:hedgehog, :analytics, :event],
      &handle_event/4,
      %{pid: self()}
    )

    {:producer, %{queue: :queue.new(), demand: 0}}
  end

  defp handle_event(_event, _measurements, metadata, %{pid: pid}) do
    event = Event.from_telemetry_event(metadata)
    GenStage.cast(pid, {:push, event})
  end

  @impl true
  def handle_cast({:push, event}, %{queue: queue, demand: demand} = state) do
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

    messages =
      Enum.map(events, &%Message{data: &1, acknowledger: {__MODULE__, :ack_id, %{pid: self()}}})

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
