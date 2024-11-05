defmodule Hedgehog do
  @moduledoc "README.md"
             |> File.read!()
             |> String.split("<!-- MDOC !-->")
             |> Enum.fetch!(1)

  @external_resource "README.md"

  defdelegate child_spec(options), to: Hedgehog.Supervisor
end
