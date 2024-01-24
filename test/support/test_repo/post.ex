defmodule AbsintheRelayDataloader.TestRepo.Post do
  use Ecto.Schema

  schema "posts" do
    belongs_to(:user, AbsintheRelayDataloader.TestRepo.User)
    has_many(:likes, AbsintheRelayDataloader.TestRepo.Like)
    has_many(:scores, AbsintheRelayDataloader.TestRepo.Score)
    has_many(:liking_users, through: [:likes, :user])

    field(:title, :string)
    field(:status, :string)
    field(:deleted_at, :utc_datetime)
  end
end
