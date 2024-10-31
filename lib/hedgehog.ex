defmodule Hedgehog do
  defdelegate child_spec(options), to: Hedgehog.Supervisor

  @opts_schema [
    datacenter: [
      type: :string,
      default: "eu"
    ],
    distribution_id: [
      type: :string,
      required: true
    ],
    distribution_secret: [
      type: :string,
      required: true
    ],
    locales: [
      type: {:list, :string},
      required: true
    ],
    namespace: [
      type: :string,
      default: "default"
    ],
    fetch_interval: [
      type: :non_neg_integer,
      default: 600_000
    ],
    otp_app: [
      type: :atom
    ]
  ]
end
