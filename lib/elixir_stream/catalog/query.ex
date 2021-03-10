defmodule ElixirStream.Catalog.Query do
  import Ecto.Query
  alias ElixirStream.Catalog.Tip

  def search(queryable \\ Tip, search_terms) do
    queryable
    |> where([q], fragment("? @@ websearch_to_tsquery('english', ?)", q.searchable, ^search_terms))
    |> order_by_latest()
    |> limit(10)
  end

  def approved(queryable \\ Tip) do
    where(queryable, [q], q.approved == true)
  end

  def order_by_latest(queryable \\ Tip) do
    order_by(queryable, [q], desc: q.published_at)
  end

  def order_by_likes(queryable \\ Tip) do
    order_by(queryable, [q], desc: q.published_at)
  end

  def preload_contributor(queryable \\ Tip) do
    queryable
    |> join(:left, [q], c in assoc(q, :contributor))
    |> preload([_q, c], contributor: c)
  end
end
