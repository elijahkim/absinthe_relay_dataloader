defmodule AbsintheRelayDataloader.SchemaTest do
  use AbsintheRelayDataloader.Case, async: true

  alias AbsintheRelayDataloader.TestRepo.{
    Post,
    User
  }

  alias AbsintheRelayDataloader.TestRepo
  alias TestRepo.Schema

  describe "#connection_loader" do
    test "can resolve a field with relay metadata" do
      user = TestRepo.insert!(%User{})
      _post_1 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 1"})
      _post_2 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 2"})

      doc = """
      {
        user(id: #{user.id}) {
          posts {
            edges {
              cursor
              node {
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)

      assert %{
               "user" => %{
                 "posts" => %{
                   "edges" => [
                     %{"cursor" => cursor_1, "node" => %{"title" => "Yo! - 1"}},
                     %{"cursor" => cursor_2, "node" => %{"title" => "Yo! - 2"}}
                   ],
                   "pageInfo" => %{
                     "endCursor" => cursor_2,
                     "hasNextPage" => false,
                     "hasPreviousPage" => false,
                     "startCursor" => cursor_1
                   }
                 }
               }
             } = data
    end

    test "it works with filtered relations" do
      user = TestRepo.insert!(%User{})
      _post_1 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 1", status: "published"})
      _post_2 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 2"})

      doc = """
      {
        user(id: #{user.id}) {
          publishedPosts {
            edges {
              cursor
              node {
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)

      assert %{
               "user" => %{
                 "publishedPosts" => %{
                   "edges" => [
                     %{"cursor" => cursor_1, "node" => %{"title" => "Yo! - 1"}}
                   ],
                   "pageInfo" => %{
                     "endCursor" => cursor_1,
                     "hasNextPage" => false,
                     "hasPreviousPage" => false,
                     "startCursor" => _cursor_2
                   }
                 }
               }
             } = data
    end

    test "It can do a basic pagination" do
      user = TestRepo.insert!(%User{})
      _post_1 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 1", status: "published"})
      _post_2 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 2"})

      doc = """
      {
        user(id: #{user.id}) {
          posts(first: 1) {
            edges {
              cursor
              node {
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)

      assert %{
               "user" => %{
                 "posts" => %{
                   "edges" => [
                     %{"cursor" => cursor_1, "node" => %{"title" => "Yo! - 1"}}
                   ],
                   "pageInfo" => %{
                     "endCursor" => cursor_1,
                     "hasNextPage" => true,
                     "hasPreviousPage" => false,
                     "startCursor" => _cursor_2
                   }
                 }
               }
             } = data
    end

    test "It can fetch the 2nd page" do
      user = TestRepo.insert!(%User{})
      _post_1 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 1", status: "published"})
      _post_2 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 2"})

      page_1 = """
      {
        user(id: #{user.id}) {
          id
          posts(first: 1) {
            edges {
              cursor
              node {
                id
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(page_1, Schema)

      cursor = data["user"]["posts"]["pageInfo"]["endCursor"]

      page_2 = """
      {
        user(id: #{user.id}) {
          posts(first: 1, after: "#{cursor}") {
            edges {
              cursor
              node {
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(page_2, Schema)


      [edge] = data["user"]["posts"]["edges"] 

      assert edge["node"]["title"] == "Yo! - 2"
    end

    test "It can go backwards" do
      user = TestRepo.insert!(%User{})
      _post_1 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 1", status: "published"})
      _post_2 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 2"})

      page_1 = """
      {
        user(id: #{user.id}) {
          id
          posts(last: 1) {
            edges {
              cursor
              node {
                id
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(page_1, Schema)


      [edge] = data["user"]["posts"]["edges"] 
      cursor = data["user"]["posts"]["pageInfo"]["endCursor"]

      assert edge["node"]["title"] == "Yo! - 2"

      page_2 = """
      {
        user(id: #{user.id}) {
          posts(last: 1, before: "#{cursor}") {
            edges {
              cursor
              node {
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(page_2, Schema)

      [edge] = data["user"]["posts"]["edges"] 

      assert edge["node"]["title"] == "Yo! - 1"
    end
  end

  describe "#node_loader" do
    test "can resolve a field" do
      user = TestRepo.insert!(%User{username: "Ben"})
      post = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 1"})

      doc = """
      {
        post(id: #{post.id}) {
          title
          user {
            username
          }
        }
      }
      """

      assert {:ok, %{data: data}} = Absinthe.run(doc, Schema)

      assert %{
               "post" => %{
                 "title" => "Yo! - 1",
                 "user" => %{
                   "username" => "Ben"
                 }
               }
             } = data
    end
  end

  describe "Passing a query" do
    test "can pass my own query function" do
      user = TestRepo.insert!(%User{})
      _post_1 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 1", status: "published"})
      _post_2 = TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 2"})

      doc = """
      {
        user(id: #{user.id}) {
          id
          loaderWithQueryPosts(first: 2) {
            edges {
              cursor
              node {
                id
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(doc, Schema)

      assert %{
               "user" => %{
                 "loaderWithQueryPosts" => %{
                   "edges" => [
                     %{"cursor" => cursor_1, "node" => %{"title" => "Yo! - 1"}},
                   ],
                   "pageInfo" => %{
                     "endCursor" => cursor_1,
                     "hasNextPage" => false,
                     "hasPreviousPage" => false,
                     "startCursor" => cursor_1
                   }
                 }
               }
             } = data
    end

    test "Pagination still works" do
      user = TestRepo.insert!(%User{})
      TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 1", status: "published"})
      TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 2"})
      TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 3"})
      TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 4", status: "published"})
      TestRepo.insert!(%Post{user_id: user.id, title: "Yo! - 5"})

      doc = """
      {
        user(id: #{user.id}) {
          id
          posts(first: 2) {
            edges {
              cursor
              node {
                id
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
          loaderWithQueryPosts(first: 2) {
            edges {
              cursor
              node {
                id
                title
              }
            }
            pageInfo {
              endCursor
              hasNextPage
              hasPreviousPage
              startCursor
            }
          }
        }
      }
      """

      {:ok, %{data: data}} = Absinthe.run(doc, Schema)

      assert %{
        "user" => %{
          "loaderWithQueryPosts" => %{
            "edges" => [
              %{
                "cursor" => query_2_start_cursor,
                "node" => %{"title" => "Yo! - 1", "id" => _}
              },
              %{
                "cursor" => query_1_end_cursor,
                "node" => %{"id" => _, "title" => "Yo! - 4"}
              }
            ],
            "pageInfo" => %{
              "endCursor" => query_1_end_cursor,
              "hasNextPage" => false,
              "hasPreviousPage" => false,
              "startCursor" => query_2_start_cursor
            }
          },
          "id" => _,
          "posts" => %{
            "edges" => [
              %{
                "cursor" => query_2_start_cursor,
                "node" => %{"id" => _, "title" => "Yo! - 1"}
              },
              %{
                "cursor" => query_2_end_cursor,
                "node" => %{"id" => _, "title" => "Yo! - 2"}
              }
            ],
            "pageInfo" => %{
              "endCursor" => query_2_end_cursor,
              "hasNextPage" => true,
              "hasPreviousPage" => false,
              "startCursor" => query_2_start_cursor
            }
          }
        }
      } = data
    end
  end
end
