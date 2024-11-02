defmodule Hedgehog.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(options) do
    name = Keyword.fetch!(options, :name)
    Supervisor.start_link(__MODULE__, options, name: name)
  end

  @impl Supervisor
  def init(options) do
    children =
      if get_in(options, [:analytics, :enabled]) do
        [{Hedgehog.Config, options}, Hedgehog.Analytics]
      else
        [{Hedgehog.Config, options}]
      end

    Supervisor.init(children, strategy: :one_for_one)
  end
end
