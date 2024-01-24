defmodule AbsintheRelayDataloader.TestRepo.Score do
  use Ecto.Schema

  schema "scores" do
    belongs_to(:post, AbsintheRelayDataloader.TestRepo.Post)
    belongs_to(:leaderboard, AbsintheRelayDataloader.TestRepo.Leaderboard)
  end
end
