defmodule Hedgehog.Analytics.Event do
  @moduledoc false
  @derive Jason.Encoder
  defstruct [:event, :properties, :distinct_id, :timestamp]

  def from_telemetry_event(%{event: event, user_id: user_id, metadata: metadata}) do
    %__MODULE__{
      event: event,
      distinct_id: user_id,
      properties: Map.put(metadata, "$lib", "hedgehog"),
      timestamp: DateTime.to_iso8601(DateTime.utc_now())
    }
  end
end
