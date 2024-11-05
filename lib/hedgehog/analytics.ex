defmodule Hedgehog.Analytics do
  @moduledoc false

  use Broadway

  alias Broadway.Message
  alias Hedgehog.Analytics.Producer
  alias Hedgehog.Client

  require Logger

  def start_link(_options) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Producer, []}
      ],
      processors: [
        default: [concurrency: 50]
      ],
      batchers: [
        posthog: [
          concurrency: 5,
          batch_size: Hedgehog.Config.get([:analytics, :batch_size]),
          batch_timeout: Hedgehog.Config.get([:analytics, :batch_timeout])
        ]
      ]
    )
  end

  def handle_message(_processor_name, message, _context) do
    Message.put_batcher(message, :posthog)
  end

  def handle_batch(:posthog, messages, _batch_info, _context) do
    messages
    |> Enum.map(& &1.data)
    |> Client.batch()
    |> case do
      {:ok, %{status: status}} when status in 200..299 ->
        messages

      _ ->
        Enum.map(messages, &Broadway.Message.failed(&1, :error))
    end
  end

  def event(event, user_id, metadata) do
    :telemetry.execute(
      [:hedgehog, :analytics, :event],
      %{},
      %{event: event, user_id: user_id, metadata: metadata}
    )
  end

  def identify(user, metadata, opts \\ []) do
    Task.start(fn -> Client.identify(user, metadata, opts) end)
  end

  def identify_group(type, id, metadata, opts \\ []) do
    Task.start(fn -> Client.identify_group(type, id, metadata, opts) end)
  end
end
