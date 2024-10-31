defmodule Hedgehog.Supervisor do
  use Supervisor

  @options [
    name: [
      type: :atom,
      default: Hedgehog
    ]
  ]

  def start_link(options) when is_list(options) do
    with {:ok, options} <- NimbleOptions.validate(options, @options) do
      name = Keyword.fetch!(options, :name)
      Supervisor.start_link(__MODULE__, options, name: name)
    end
  end

  @impl Supervisor
  def init(_options) do
    children = [
      {Hedgehog.Analytics, []}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
