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
      {:ok, validated} ->
        children =
          if get_in(validated, [:analytics, :enabled]) do
            [{Hedgehog.Config, validated}, Hedgehog.Analytics]
          else
            [{Hedgehog.Config, validated}]
          end

        Supervisor.init(children, strategy: :one_for_one)

      {:error, error} ->
        {:error, {:invalid_options, error}}
    end
  end
end
