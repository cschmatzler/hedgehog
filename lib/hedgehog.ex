defmodule Hedgehog do
  @moduledoc false
  defdelegate child_spec(options), to: Hedgehog.Supervisor
end
