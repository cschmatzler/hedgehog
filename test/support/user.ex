defmodule Hedgehog.Test.User do
  @moduledoc false

  use Hedgehog.User

  defstruct [:id, :groups]

  def groups(%__MODULE__{groups: groups}, _), do: groups
end
