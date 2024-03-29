defmodule AbsintheRelayDataloader.Helpers do
  def node_loader(source, {schema, args}, id, %{context: %{loader: loader}}) do
    loader
    |> Dataloader.load(source, {schema, args}, id)
    |> Absinthe.Resolution.Helpers.on_load(fn loader ->
      result = Dataloader.get(loader, source, {schema, args}, id)
      {:ok, result}
    end)
  end

  def node_loader(source, schema, id, res) do
    node_loader(source, {schema, %{}}, id, res)
  end

  @doc """
  Resolve a node using dataloader and an Ecto association that
  matches the name of the field being resolved.
  # Example
      field :artist, :artist, resolve: Relay.node_dataloader(Chinook.Loader)
  """
  def node_loader(source) do
    fn parent, args, res = %{context: %{loader: loader}} ->
      assoc = res.definition.schema_node.identifier

      args = node_fields(args, res)

      loader
      |> Dataloader.load(source, {assoc, args}, parent)
      |> Absinthe.Resolution.Helpers.on_load(fn loader ->
        result = Dataloader.get(loader, source, {assoc, args}, parent)
        {:ok, result}
      end)
    end
  end

  defp node_fields(args, resolution) do
    query_fields = resolution |> Absinthe.Resolution.project()
    selected_node_fields = Enum.map(query_fields, fn x -> x.schema_node.identifier end)
    Map.put(args, :fields, selected_node_fields)
  end

  @doc """
  Resolve a connection using dataloader and an Ecto association that
  matches the name of the field being resolved.
  # Example
      connection field :invoices, node_type: :invoice do
        arg :by, :invoice_sort_order, default_value: :invoice_id
        arg :filter, :invoice_filter, default_value: %{}
        middleware Scope, [read: :invoice]
        resolve Relay.connection_dataloader(Chinook.Loader)
      end
  """
  def connection_loader(source) do
    connection_loader(source, fn parent, args, res ->
      resource = res.definition.schema_node.identifier
      {resource, args, parent}
    end)
  end

  def connection_loader(source, base_args) when is_map(base_args) do
    connection_loader(source, fn parent, args, res ->
      resource = res.definition.schema_node.identifier
      {resource, Map.merge(base_args, args), parent}
    end)
  end

  def connection_loader(source, fun) when is_function(fun) do
    fn parent, args, res = %{context: %{loader: loader}} ->
      args = decode_cursor(args)

      {batch_key, batch_value} =
        case fun.(parent, args, res) do
          {schema, args, [{foreign_key, val}]} ->
            args = connection_fields(args, res)
            {{{:many, schema}, args}, [{foreign_key, val}]}

          {assoc, args, parent} when is_atom(assoc) and is_struct(parent) ->
            args =
              args
              |> connection_fields(res)
              |> relation(parent, assoc)
              |> binding(assoc)

            {{assoc, args}, parent}
        end

      loader
      |> Dataloader.load(source, batch_key, batch_value)
      |> Absinthe.Resolution.Helpers.on_load(fn loader ->
        loader
        |> Dataloader.get(source, batch_key, batch_value)
        |> connection_from_slice(args)
      end)
    end
  end

  def connection_from_slice(items, pagination_args) do
    items =
      case pagination_args do
        %{last: _} -> Enum.reverse(items)
        _ -> items
      end

    count = Enum.count(items)
    {edges, first, last} = build_cursors(items, pagination_args)

    # TODO: use a protocol for `row_count` instead of assuming field available
    row_count =
      case items do
        [] -> 0
        [%{row_count: n} | _rest] -> n
        list when is_list(list) -> Enum.count(list)
      end

    page_info = %{
      start_cursor: first,
      end_cursor: last,
      has_previous_page:
        case pagination_args do
          %{after: _} -> true
          %{last: ^count} -> row_count > count
          _ -> false
        end,
      has_next_page:
        case pagination_args do
          %{before: _} -> true
          %{first: ^count} -> row_count > count
          _ -> false
        end
    }

    {:ok, %{edges: edges, page_info: page_info}}
  end

  defp connection_fields(args, resolution) do
    query_fields = resolution |> Absinthe.Resolution.project()

    with edge_fields = %Absinthe.Blueprint.Document.Field{} <-
           Enum.find(query_fields, fn x -> x.schema_node.identifier == :edges end),
         node_fields = %Absinthe.Blueprint.Document.Field{} <-
           Enum.find(edge_fields.selections, fn x -> x.schema_node.identifier == :node end) do
      selected_node_fields =
        Enum.map(node_fields.selections, fn x -> x.schema_node.identifier end)

      Map.put(args, :fields, selected_node_fields)
    else
      _ -> args
    end
  end

  defp build_cursors([], _pagination_args), do: {[], nil, nil}

  defp build_cursors([item | items], pagination_args) do
    first = item_cursor(item, pagination_args)
    edge = build_edge(item, first)
    {edges, last} = do_build_cursors(items, pagination_args, [edge], first)
    {edges, first, last}
  end

  defp do_build_cursors([], _pagination_args, edges, last), do: {Enum.reverse(edges), last}

  defp do_build_cursors([item | rest], pagination_args, edges, _last) do
    cursor = item_cursor(item, pagination_args)

    edge = build_edge(item, cursor)
    do_build_cursors(rest, pagination_args, [edge | edges], cursor)
  end

  def relation(args, schema, key) do
    %{related: related} = get_related_schema(schema, key)
    Map.put(args, :schema, related)
  end

  def binding(args, binding) do
    Map.put(args, :binding, binding)
  end

  defp get_related_schema(%module{}, key) do
    module.__schema__(:association, key)
  end

  defp item_cursor(item, %{by: field}) do
    [pk] = item.__struct__.__schema__(:primary_key)
    "#{field}|#{pk}|#{Map.get(item, pk)}" |> Base.encode64()
  end

  defp item_cursor(item, _) do
    item_cursor(item, %{by: :id})
  end

  defp build_edge(item, cursor) do
    %{
      node: item,
      cursor: cursor
    }
  end

  defp decode_cursor(pagination_args) do
    pagination_args
    |> decode_cursor_arg(:after)
    |> decode_cursor_arg(:before)
  end

  defp decode_cursor_arg(pagination_args, arg) do
    case pagination_args do
      %{^arg => cursor} ->
        [by, pk, id] = cursor |> Base.decode64!() |> String.split("|", parts: 3)

        pagination_args
        |> Map.put(:by, String.to_existing_atom(by))
        |> Map.put(arg, [{String.to_existing_atom(pk), id}])

      _ ->
        pagination_args
    end
  end
end
