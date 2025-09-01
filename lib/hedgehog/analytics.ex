defmodule Hedgehog.Analytics do
  @moduledoc false

  use Supervisor

  alias Hedgehog.Analytics.Buffer
  alias Hedgehog.Client

  require Logger

  def start_link(_options) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl Supervisor
  def init(_options) do
    children = [
      Buffer
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def event(event, user_id, metadata \\ %{}) do
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
