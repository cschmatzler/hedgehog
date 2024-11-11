options =
  NimbleOptions.new!(
    name: [
      type: :atom,
      default: Hedgehog,
      doc: "The unique name of the Hedgehog supervisor."
    ],
    endpoint: [
      type: :string,
      required: true,
      doc: "The public endpoint of your Posthog instance, including the protocol."
    ],
    api_key: [
      type: :string,
      required: true,
      doc: "Your Posthog Project API key."
    ],
    analytics: [
      type: :keyword_list,
      doc: "Settings for the Hedgehog analytics module.",
      keys: [
        enabled: [
          type: :boolean,
          default: true,
          doc: "Enable or disable the analytics module entirely."
        ],
        user: [
          type: :atom,
          doc: """
          The user module to use for user tracking.

          This module must implement the `Hedgehog.User` behaviour.
          """
        ],
        pageview: [
          type: :boolean,
          default: false,
          doc: "Automatically track Phoenix pageviews. Requires the `user` option to be set."
        ],
        batch_size: [
          type: :pos_integer,
          default: 500,
          doc: "The maximum number of events to send in a batch."
        ],
        batch_timeout: [
          type: :pos_integer,
          default: 10_000,
          doc: "The maximum time to wait for a batch to be sent."
        ]
      ]
    ]
  )

defmodule Hedgehog.Config do
  @moduledoc """
  Configuration options for Hedgehog.

  Supported options:  
  #{NimbleOptions.docs(options)}
  """

  use Agent

  @options options
  @doc false
  def options, do: @options

  @doc false
  def start_link(options) do
    case NimbleOptions.validate(options, @options) do
      {:ok, options} ->
        Agent.start_link(fn -> options end, name: __MODULE__)

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end

  @doc """
  Returns the value for the given key, or the default value if the key is not present.

  The second argument is either an atom key or a path to traverse in search of the configuration, starting with an atom key.
  """
  def get(key_or_path, default \\ nil)

  def get(path, default) when is_list(path) do
    Agent.get(__MODULE__, fn options ->
      get_in(options, path) || default
    end)
  end

  def get(key, default) when is_atom(key) do
    Agent.get(__MODULE__, fn options -> Keyword.get(options, key, default) end)
  end
end
