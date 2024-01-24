defmodule AbsintheRelayDataloader.TestRepo do
  use Ecto.Repo,
    otp_app: :absinthe_relay_dataloader,
    adapter: Ecto.Adapters.Postgres
end
