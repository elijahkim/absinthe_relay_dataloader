defmodule AbsintheRelayDataloader.TestRepo.UserPicture do
  use Ecto.Schema

  schema "user_pictures" do
    field(:status, :string)
    belongs_to(:picture, AbsintheRelayDataloader.TestRepo.Picture)
    belongs_to(:user, AbsintheRelayDataloader.TestRepo.User)
  end
end
