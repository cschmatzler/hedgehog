defmodule Hedgehog.Config do
  @moduledoc false
  use Agent

  @options NimbleOptions.new!(
             name: [
               type: :atom,
               default: Hedgehog
             ],
             endpoint: [
               type: :string,
               required: true
             ],
             api_key: [
               type: :string,
               required: true
             ],
             analytics: [
               type: :keyword_list,
               default: [],
               keys: [
                 enabled: [
                   type: :boolean,
                   default: true
                 ],
                 user: [
                   type: :atom
                 ],
                 pageview: [
                   type: :boolean,
                   default: false
                 ],
                 batch_size: [
                   type: :pos_integer,
                   default: 500
                 ],
                 batch_timeout: [
                   type: :pos_integer,
                   default: 10_000
                 ]
               ]
             ]
           )

  def start_link(options) do
    case NimbleOptions.validate(options, @options) do
      {:ok, validated} ->
        Agent.start_link(fn -> validated end, name: __MODULE__)

      {:error, error} ->
        {:error, error}
    end
  end

  def get(key_or_keys, default \\ nil)

  def get(keys, default) when is_list(keys) do
    Agent.get(__MODULE__, fn options ->
      get_in(options, keys) || default
    end)
  end

  def get(key, default) when is_atom(key) do
    Agent.get(__MODULE__, fn options -> Keyword.get(options, key, default) end)
  end

  def options, do: @options
end
