# Hedgehog

[![Hex.pm](https://img.shields.io/hexpm/v/hedgehog.svg)](https://hex.pm/packages/hedgehog) [![Documentation](https://img.shields.io/badge/documentation-gray)](https://hexdocs.pm/hedgehog/)

<!-- MDOC !-->

An extra-spiky Posthog SDK with a focus on minimal API surface and Elixir-isms.

[Posthog](https://posthog.com/) is great! It's a product chock-full of features, great pricing and amazing transparency that many companies
should aim to copy. It's also missing a great Elixir SDK, which is a hole that Hedgehog is looking to fill.

> [!WARNING]
> This is currently a work in progress. It's pre-0.1 and will constantly change. Documentation is sparse and not properly tested.

## Installation

Add `hedgehog` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:hedgehog, "~> 0.0.1"}
  ]
end
```

Then, add it to your application as a child:

```elixir
defmodule MyApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {Hedgehog, Application.get_all_env(:hedgehog)},
    ]

    opts = [strategy: :one_for_one, name: MyApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

Some configuration options come with sensible defaults, others are required. We will go over the optional ones in the following sections,
but these are the required ones:

```elixir
config :hedgehog,
  api_key: "phc_TBvjhk9ovZkg6HbRgq3TDCvA5Ww05FafOXfVIclGoDo", # your _Project_ API key
  endpoint: "https://eu.i.posthog.com", # the _public_ endpoint of your Posthog instance, including the protocol
```

## Analytics

Hedgehog's current main module is all about analytics. It hooks into Erlang's `:telemetry` module, transforms telemetry events to Posthog
events, batches them and sends them to your Posthog instance.

### Configuration

The following configuration options are available, with their defaults:

```elixir
config :hedgehog,
  analytics: [
    enabled: true, # enable analytics - the following options are ignored if this is false
    pageview: false, # whether to automatically handle Phoenix LiveView pageviews
    batch_size: 500, # the maximum number of events to send in a batch
    batch_timeout: 10_000, # the maximum time to wait for a batch to be sent
    user: Hedgehog.User # your user module - required if `pageview` is true
  ]
```

### The User module

When enabling automatic tracking of LiveView pages, Hedgehog needs to know who the currently logged in user is. In order to facilitate this,
it requires a module that implements the `Hedgehog.User` behaviour.
