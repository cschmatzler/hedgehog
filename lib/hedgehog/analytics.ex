defmodule Hedgehog.Analytics do
  @moduledoc false

  use Broadway

  alias Broadway.Message
  alias Hedgehog.Client
  alias Hedgehog.Analytics.Producer

  require Logger

  @enabled? Application.compile_env(:leuchtturm, [Leuchtturm.Analytics, :enabled?], false)

  def start_link(_opts) do
    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Producer, []}
      ],
      processors: [
        default: [concurrency: 50]
      ],
      batchers: [
        posthog: [concurrency: 5, batch_size: 500, batch_timeout: 60_000]
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

  defmacro event(event_name, metadata) do
    if @enabled? do
      quote do
        :telemetry.execute(
          [:leuchtturm, :analytics, unquote(event_name)],
          %{},
          unquote(metadata)
        )
      end
    else
      quote do
        _ = fn -> {unquote(event_name), unquote(metadata)} end
        :ok
      end
    end
  end

  def identify_workspace(%{id: id, name: name, slug: slug}, opts \\ []) do
    if @enabled?,
      do: Task.start(fn -> Client.identify_workspace(%{id: id, name: name, slug: slug}, opts) end)
  end
end
