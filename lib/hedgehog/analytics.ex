defmodule Hedgehog.Analytics do
  @moduledoc false

  use Broadway

  alias Broadway.Message
  alias Hedgehog.Analytics.Producer
  alias Hedgehog.Client

  require Logger

  @enabled Application.compile_env(:hedgehog, [:analytics, :enabled], false)

  def start_link(options) do
    {broadway, producer} = Keyword.split(options, [:batch_size, :batch_timeout])

    Broadway.start_link(__MODULE__,
      name: __MODULE__,
      producer: [
        module: {Producer, producer}
      ],
      processors: [
        default: [concurrency: 50]
      ],
      batchers: [
        posthog: [
          concurrency: 5,
          batch_size: Keyword.fetch!(broadway, :batch_size),
          batch_timeout: Keyword.fetch!(broadway, :batch_timeout)
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

  if @enabled do
    def event(event, user, metadata) do
      IO.puts("doing something")

      :telemetry.execute(
        [:hedgehog, :analytics, :event],
        %{},
        %{event: event, user: user, metadata: metadata}
      )
    end

    def identify_group(group, metadata, opts \\ []) do
      Task.start(fn -> Client.identify_group(group, metadata, opts) end)
    end
  else
    def event(_event, _metadata, _actor) do
      IO.puts("doing nothing")
      :ok
    end

    def identify_workspace(_workspace, _opts), do: :ok
  end
end
