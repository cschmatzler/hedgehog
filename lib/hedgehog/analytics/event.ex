defmodule Hedgehog.Analytics.Event do
  @moduledoc false
  alias Hedgehog.Config

  @derive Jason.Encoder
  defstruct [:event, :distinct_id, :properties, :timestamp]

  def from_telemetry_event(%{event: event, user_id: user_id, metadata: metadata}) do
    %__MODULE__{
      event: event,
      distinct_id: user_id,
      properties: Map.put(metadata, "$lib", "hedgehog"),
      timestamp: DateTime.to_iso8601(DateTime.utc_now())
    }
  end

  def pageview(metadata) do
    current_url = to_string(metadata.uri)

    user_module = Config.get([:analytics, :user_module])
    user = apply(user_module, :from_view, [metadata.socket])
    user_id = apply(user_module, :id, [user])

    %__MODULE__{
      event: "$pageview",
      distinct_id: user_id,
      properties: %{
        "$current_url" => current_url,
        "$lib" => "hedgehog"
      },
      timestamp: DateTime.to_iso8601(DateTime.utc_now())
    }
  end
end
