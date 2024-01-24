defmodule AbsintheRelayDataloader.TestRepo.Picture do
  use Ecto.Schema

  schema "pictures" do
    field(:status, :string)
    field(:url, :string)
    has_many(:likes, AbsintheRelayDataloader.TestRepo.Like)

    has_many(:published_likes, AbsintheRelayDataloader.TestRepo.Like,
      where: [status: "published"]
    )
  end
end
