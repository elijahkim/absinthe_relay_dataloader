defmodule AbsintheRelayDataloader.TestRepo.Like do
  use Ecto.Schema

  schema "likes" do
    belongs_to(:user, AbsintheRelayDataloader.TestRepo.User)
    belongs_to(:post, AbsintheRelayDataloader.TestRepo.Post, where: [status: "published"])
    belongs_to(:picture, AbsintheRelayDataloader.TestRepo.Picture)
    field(:status, :string)
  end
end
