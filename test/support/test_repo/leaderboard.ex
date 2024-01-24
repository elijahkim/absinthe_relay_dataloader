defmodule AbsintheRelayDataloader.TestRepo.Leaderboard do
  use Ecto.Schema

  schema "leaderboards" do
    field(:name, :string)
    has_many(:scores, AbsintheRelayDataloader.TestRepo.Score)
    has_many(:users, AbsintheRelayDataloader.TestRepo.User)
    has_many(:user_pictures, through: [:users, :pictures])
    has_many(:user_pictures_published, through: [:users, :pictures_published])
    has_many(:user_pictures_likes, through: [:users, :pictures, :likes])
    has_many(:user_pictures_published_likes, through: [:users, :pictures_published, :likes])
    has_many(:user_published_posts_likes, through: [:users, :published_posts, :likes])
  end
end
