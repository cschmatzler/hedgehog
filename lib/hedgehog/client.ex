defmodule Hedgehog.Client do
  @moduledoc false
  def new(_opts \\ []) do
    [base_url: Application.get_env(:hedgehog, :domain)]
    |> Req.new()
    |> Req.Request.append_request_steps(
      api_key: fn req ->
        with %{method: :post, body: body} <- req do
          # FIXME: This is ugly?
          body = body |> Jason.decode!() |> Map.put(:api_key, Application.get_env(:hedgehog, :api_key)) |> Jason.encode!()
          IO.inspect(%{req | body: body})
        end
      end
    )
  end

  def post(url, json, opts \\ []) do
    json = Map.put(json, :api_key, Application.get_env(:hedgehog, :api_key))
    opts = Keyword.put(opts, :json, json)

    [url: url]
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
