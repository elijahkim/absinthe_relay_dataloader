{:ok, _} = AbsintheRelayDataloader.TestRepo.start_link()
Ecto.Adapters.SQL.Sandbox.mode(AbsintheRelayDataloader.TestRepo, :auto)

ExUnit.start()
