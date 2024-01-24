import Config

config :absinthe_relay_dataloader, AbsintheRelayDataloader.TestRepo,
  hostname: "localhost",
  username: "postgres",
  password: "postgres",
  database: "dataloader_test",
  pool: Ecto.Adapters.SQL.Sandbox

config :absinthe_relay_dataloader, ecto_repos: [AbsintheRelayDataloader.TestRepo]

config :logger, level: :warn
