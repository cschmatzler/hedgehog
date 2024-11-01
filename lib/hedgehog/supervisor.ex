defmodule Hedgehog.Supervisor do
  @moduledoc false
  use Supervisor

  @options NimbleOptions.new!(
             name: [
               type: :atom,
               default: Hedgehog
             ],
             domain: [
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
                   default: false
                 ],
                 batch_size: [
                   type: :pos_integer,
                   default: 500
                 ],
                 batch_timeout: [
                   type: :pos_integer,
                   default: 60_000
                 ]
               ]
             ]
           )

  def start_link(options) do
    with {:ok, options} <- NimbleOptions.validate(options, @options) do
      name = Keyword.fetch!(options, :name)

      Supervisor.start_link(__MODULE__, options, name: name)
    end
  end

  @impl Supervisor
  def init(options) do
    with {:ok, options} <- NimbleOptions.validate(options, @options) do
      children =
        if get_in(options, [:analytics, :enabled]) do
          [{Hedgehog.Analytics, Keyword.get(options, :analytics, [])}]
        else
          []
        end

      Supervisor.init(children, strategy: :one_for_one)
    end
  end
end
