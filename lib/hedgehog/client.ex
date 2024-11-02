defmodule Hedgehog.Client do
  @moduledoc false
  alias Hedgehog.Config

  def new(opts \\ []) do
    [base_url: Config.get(:endpoint)]
    |> Req.new()
    |> Req.merge(opts)
  end

  def post(url, json, opts \\ []) do
    json = Map.put(json, :api_key, Config.get(:api_key))

    [url: url, json: json]
    |> new()
    |> Req.post(opts)
  end

  def batch(events) do
    post("/batch", %{batch: events})
  end

  def identify_group(type, id, metadata, _opts) do
    post("/capture", %{
      event: "$groupidentify",
      distinct_id: id,
      properties: %{
        "$group_type" => type,
        "$group_key" => id,
        "$group_set" => metadata,
        "$lib" => "hedgehog"
      }
    })
  end
end
