defmodule Hedgehog.Client do
  @posthog_api_key Application.compile_env(:leuchtturm, [Leuchtturm.Analytics, :posthog_api_key])

  def new(opts \\ []) when is_list(opts) do
    [base_url: "https://eu.i.posthog.com"]
    |> Req.new()
    |> Req.merge(opts)
  end

  def post(url, json, opts \\ []) do
    json = Map.put(json, :api_key, @posthog_api_key)
    opts = Keyword.put(opts, :json, json)

    [url: url]
    |> new()
    |> Req.post(opts)
  end

  def batch(events) do
    post("/batch", %{batch: events})
  end

  def identify_workspace(%{id: id, name: name, slug: slug}, opts) do
    actor = Keyword.get(opts, :actor)

    post("/capture", %{
      event: "$groupidentify",
      distinct_id: actor.id,
      properties: %{
        "$group_type" => "workspace",
        "$group_key" => id,
        "$group_set" => %{
          name: name,
          slug: slug
        },
        "$lib" => "server"
      }
    })
  end
end
