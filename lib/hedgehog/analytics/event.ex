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

  def from_telemetry_event(_), do: nil

  def pageview(metadata) do
    mod = Config.get([:analytics, :user])

    with true <- Phoenix.LiveView.connected?(metadata.socket),
         user when not is_nil(user) <- apply(mod, :from_view, [metadata.socket]),
         user_id when not is_nil(user_id) <- apply(mod, :id, [user]) do
      %__MODULE__{
        event: "$pageview",
        distinct_id: user_id,
        properties: %{
          "$current_url" => to_string(metadata.uri),
          "$lib" => "hedgehog"
        },
        timestamp: DateTime.to_iso8601(DateTime.utc_now())
      }
    else
      _ -> nil
    end
  end
end
