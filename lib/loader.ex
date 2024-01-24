defmodule AbsintheRelayDataloader.Loader do
  alias AbsintheRelayDataloader.QueryHelpers

  import Ecto.Query

  def new(repo, opts \\ []) do
    root_query = Keyword.get(opts, :query, &base_query/2)

    query = fn queryable, args ->
      queryable
      |> root_query.(args)
      |> do_query(args)
    end

    Dataloader.Ecto.new(repo, query: query)
  end

  def base_query(queryable, _args) do
    queryable
  end

  def do_query(queryable, args) do
    queryable
    |> add_binding(args)
    |> select_fields(args)
    |> paginate(args)
  end

  def add_binding(queryable, %{binding: binding}) do
    from(queryable, as: ^binding)
  end

  def add_binding(queryable, _) do
    queryable
  end

  def select_fields(queryable, %{fields: fields, schema: schema, binding: binding}) do
    QueryHelpers.select_fields(queryable, schema, binding, fields)
  end

  def select_fields(queryable, _) do
    queryable
  end

  def paginate(queryable, %{binding: binding, schema: schema} = args) do
    [pk] = schema.__schema__(:primary_key)
    QueryHelpers.paginate(queryable, schema, binding, Map.put_new(args, :by, pk))
  end

  def paginate(queryable, _) do
    queryable
  end
end
