defmodule AbsintheRelayDataloader.TestRepo.Schema do
  use Absinthe.Schema
  use Absinthe.Relay.Schema, :modern

  import AbsintheRelayDataloader.Helpers

  alias AbsintheRelayDataloader.{TestRepo, Loader}

  alias AbsintheRelayDataloader.TestRepo.{
    Post,
    User
  }

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end

  def base_query(queryable, _args) do
    import Ecto.Query

    where(queryable, [q], q.status == "published")
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(:loader, Loader.new(TestRepo))
      |> Dataloader.add_source(:loader_with_query, Loader.new(TestRepo, query: &base_query/2))

    Map.put(ctx, :loader, loader)
  end

  connection(node_type: :user)
  connection(node_type: :post)

  node interface do
    resolve_type(fn _, _ ->
      # We just resolve :foos for now
      :user
    end)
  end

  node object(:user) do
    field(:username, :string)

    connection(field(:posts, node_type: :post)) do
      resolve(connection_loader(:loader))
    end

    connection(field(:published_posts, node_type: :post)) do
      resolve(connection_loader(:loader))
    end

    connection field(:loader_with_query_posts, node_type: :post) do
      resolve(connection_loader(:loader_with_query))
    end
  end

  node object(:post) do
    field(:title, :string)
    field(:status, :string)

    field(:user, :user, resolve: node_loader(:loader))
  end

  query do
    field :user, :user do
      arg(:id, non_null(:id))
      resolve(&resolve_user/2)
    end

    field :post, :post do
      arg(:id, non_null(:id))
      resolve(&resolve_post/2)
    end
  end

  def resolve_user(%{id: id}, _resolution) do
    user = TestRepo.get(User, id)
    {:ok, user}
  end

  def resolve_post(%{id: id}, _resolution) do
    post = TestRepo.get(Post, id)
    {:ok, post}
  end
end
