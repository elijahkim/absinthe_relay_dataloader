defmodule AbsintheRelayDataloader.TestRepo.User do
  use Ecto.Schema

  schema "users" do
    field(:username, :string)
    has_many(:posts, AbsintheRelayDataloader.TestRepo.Post)
    has_many(:loader_with_query_posts, AbsintheRelayDataloader.TestRepo.Post)

    has_many(:published_posts, AbsintheRelayDataloader.TestRepo.Post,
      where: [status: "published"]
    )

    has_many(:published_posts_likes, through: [:published_posts, :likes])
    belongs_to(:leaderboard, AbsintheRelayDataloader.TestRepo.Leaderboard)

    has_many(:scores, through: [:posts, :scores])
    has_many(:awarded_posts, through: [:scores, :post])
    has_many(:likes, through: [:awarded_posts, :likes])

    many_to_many(:liked_posts, AbsintheRelayDataloader.TestRepo.Post,
      join_through: AbsintheRelayDataloader.TestRepo.Like
    )

    many_to_many(:liked_published_posts, AbsintheRelayDataloader.TestRepo.Post,
      join_through: AbsintheRelayDataloader.TestRepo.Like,
      where: [status: "published"]
    )

    many_to_many(:published_liked_published_posts, AbsintheRelayDataloader.TestRepo.Post,
      join_through: AbsintheRelayDataloader.TestRepo.Like,
      where: [status: "published"],
      join_where: [status: "published"]
    )

    has_many(:fans, through: [:likes, :user])

    has_many(:liked_posts_scores, through: [:liked_posts, :scores])
    has_many(:liked_published_posts_scores, through: [:liked_published_posts, :scores])

    has_many(:published_liked_published_posts_scores,
      through: [:published_liked_published_posts, :scores]
    )

    many_to_many(:pictures, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture
    )

    has_many(:published_picture_likes, through: [:pictures, :published_likes])

    many_to_many(:pictures_published, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      join_where: [status: "published"],
      where: [status: "published"]
    )

    many_to_many(:pictures_join_compare_value, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      join_where: [status: "published"]
    )

    many_to_many(:pictures_join_nil, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      join_where: [status: nil]
    )

    many_to_many(:pictures_join_in, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      join_where: [status: {:in, ["published", "blurry"]}]
    )

    many_to_many(:pictures_join_fragment, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      join_where: [status: {:fragment, "LENGTH(?) > 3"}]
    )

    many_to_many(:pictures_compare_value, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      where: [status: "published"]
    )

    many_to_many(:pictures_nil, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      where: [status: nil]
    )

    many_to_many(:pictures_in, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      where: [status: {:in, ["published", "blurry"]}]
    )

    many_to_many(:pictures_fragment, AbsintheRelayDataloader.TestRepo.Picture,
      join_through: AbsintheRelayDataloader.TestRepo.UserPicture,
      where: [status: {:fragment, "LENGTH(?) > 3"}]
    )
  end
end
