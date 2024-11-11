defmodule Hedgehog.Supervisor do
  @moduledoc false
  use Supervisor

  def start_link(options) do
    name = Keyword.get(options, :name, Hedgehog)
    Supervisor.start_link(__MODULE__, options, name: name)
  end

  @impl Supervisor
  def init(options) do
    case NimbleOptions.validate(options, Hedgehog.Config.options()) do
      {:ok, options} ->
        children =
          if get_in(options, [:analytics, :enabled]) do
            [{Hedgehog.Config, options}, Hedgehog.Analytics]
          else
            [{Hedgehog.Config, options}]
          end

        Supervisor.init(children, strategy: :one_for_one)

      {:error, exception} ->
        {:error, Exception.message(exception)}
    end
  end
end
