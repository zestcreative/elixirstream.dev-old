defmodule ElixirStream.Catalog do
  alias ElixirStream.Catalog.{Query, Tip}
  alias ElixirStream.Repo
  alias Phoenix.PubSub

  @tip_topic "tips"

  @spec find_tip(String.t()) :: nil | %Tip{}
  def find_tip(id) do
    Tip
    |> Query.approved()
    |> Query.preload_contributor()
    |> Repo.get(id)
  end

  @type tip_queryable :: :latest | :popular | Ecto.Queryable.t()

  @spec search_tips(String.t()) :: list(%Tip{})
  def search_tips(search_terms) do
    Tip
    |> Query.search(search_terms)
    |> Query.approved()
    |> list_tips()
  end

  @spec list_tips(tip_queryable) :: list(%Tip{})
  def list_tips(:latest) do
    Tip
    |> Query.order_by_latest()
    |> Query.approved()
    |> list_tips()
  end

  def list_tips(:popular) do
    Tip
    |> Query.order_by_likes()
    |> Query.approved()
    |> list_tips()
  end

  def list_tips(queryable) do
    queryable
    |> Query.preload_contributor()
    |> Query.approved()
    |> Repo.all()
  end

  defp tip_preloads(queryable) do
    Repo.preload(queryable, :contributor)
  end

  @spec create_tip(map()) :: {:ok, %Tip{}}
  def create_tip(attrs) do
    %Tip{}
    |> Tip.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, tip} ->
        tip = tip_preloads(tip)
        PubSub.broadcast(ElixirStream.PubSub, @tip_topic, [:tip, :new, tip])
        {:ok, tip}

      error ->
        error
    end
  end

  @spec approve_tip(%Tip{}) :: {:ok, %Tip{}}
  def approve_tip(tip) do
    tip
    |> Tip.changeset(%{approve: true})
    |> Repo.update()
    |> case do
      {:ok, tip} ->
        tip = tip_preloads(tip)
        PubSub.broadcast(ElixirStream.PubSub, @tip_topic, [:tip, :approved, tip])
        {:ok, tip}

      error ->
        error
    end
  end
end
