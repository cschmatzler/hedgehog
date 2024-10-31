defmodule Hedgehog.Analytics.Event do
  @derive Jason.Encoder
  defstruct [:event, :properties, :distinct_id, :timestamp]

  def from_telemetry_event(event_name, measurements, metadata) do
    event_name = event_name |> Enum.drop(2) |> Enum.join(".")
    {actor, metadata} = Map.pop(metadata, :actor)

    %__MODULE__{
      event: event_name,
      distinct_id: distinct_id(actor),
      properties: build_properties(measurements, metadata),
      timestamp: DateTime.to_iso8601(DateTime.utc_now())
    }
  end

  defp distinct_id(actor) do
    if actor, do: actor.id
  end

  defp build_properties(measurements, metadata) do
    {workspace, metadata} = Map.pop(metadata, :workspace)

    measurements
    |> Map.merge(metadata)
    |> Map.put("$lib", "server")
    |> put_groups(workspace)
  end

  defp put_groups(properties, nil), do: properties

  defp put_groups(properties, workspace),
    do: Map.put(properties, "$groups", %{workspace: workspace.id})
end
