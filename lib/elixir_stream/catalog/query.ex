defmodule ElixirStream.Catalog.Query do
  import Ecto.Query
  alias ElixirStream.Catalog.Tip

  def where_id(queryable \\ Tip, id) do
    queryable
    |> where([q], q.id == ^id)
  end

  def where_ids(queryable \\ Tip, ids) do
    queryable
    |> where([q], q.id in ^ids)
  end

  def return(queryable \\ Tip, fields) do
    select(queryable, ^fields)
  end

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

  def order_by_upvotes(queryable \\ Tip) do
    order_by(queryable, [q], [desc: q.upvote_count, desc: q.published_at])
  end

  def preload_contributor(queryable \\ Tip) do
    if has_named_binding?(queryable, :contributor) do
      queryable
    else
      queryable
      |> join(:left, [q], c in assoc(q, :contributor), as: :contributor)
      |> preload([_q, contributor: c], contributor: c)
    end
  end

  def upvoted_by(queryable \\ Tip, user_id) do
    if has_named_binding?(queryable, :upvotes) do
      queryable
    else
      queryable
      |> join(:left, [q], u in assoc(q, :upvotes), as: :upvotes)
      |> preload([_q, upvotes: u], upvotes: u)
    end
    |> where([upvotes: u], u.user_id == ^user_id)
  end
end
