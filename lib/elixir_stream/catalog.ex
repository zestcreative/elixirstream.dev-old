defmodule ElixirStream.Catalog do
  alias ElixirStream.Catalog.{Query, Tip, Upvote}
  alias ElixirStream.Accounts.{User}
  alias ElixirStream.Repo
  alias Phoenix.PubSub
  require Ecto.Query

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
    |> Query.preload_contributor()
    |> Query.search(search_terms)
    |> Query.approved()
    |> list_tips()
  end

  @spec list_tips(tip_queryable) :: list(%Tip{})
  def list_tips(:latest) do
    Tip
    |> Query.preload_contributor()
    |> Query.order_by_latest()
    |> Query.approved()
    |> list_tips()
  end

  def list_tips(:popular) do
    Tip
    |> Query.preload_contributor()
    |> Query.order_by_upvotes()
    |> Query.approved()
    |> list_tips()
  end

  def list_tips(queryable) do
    queryable
    |> Query.approved()
    |> Repo.all()
  end

  defp tip_preloads(queryable) do
    Repo.preload(queryable, :contributor)
  end

  def downvote_tip(tip_id, user) when is_binary(tip_id) do
    Tip
    |> Repo.get_by(id: tip_id)
    |> downvote_tip(user)
  end

  def downvote_tip(nil, _user), do: {:error, :tip_not_found}
  def downvote_tip(_tip, nil), do: {:error, :user_not_found}
  def downvote_tip(%Tip{contributor_id: user_id}, %User{id: user_id}), do: {:ok, nil}

  def downvote_tip(%Upvote{} = upvote, tip) do
    case Repo.delete(upvote) do
      {:ok, _upvote} ->
        {_, [%{upvote_count: count}]} =
          tip.id
          |> Query.where_id()
          |> Query.return([:upvote_count])
          |> Repo.update_all(inc: [upvote_count: -1])
        updated_tip = tip_preloads(%{tip | upvote_count: count})
        PubSub.broadcast(ElixirStream.PubSub, @tip_topic, [:tip, :update, updated_tip])
        {:ok, updated_tip}

      _error ->
        {:ok, nil}
    end
  end
  def downvote_tip(tip, user) do
    Upvote
    |> Repo.get_by(tip_id: tip.id, user_id: user.id)
    |> downvote_tip(tip)
  end

  @spec upvote_tip(String.t(), %User{}) :: {:ok, %Upvote{}} | {:error, Ecto.Changeset.t()}
  def upvote_tip(tip_id, user) when is_binary(tip_id) do
    Tip
    |> Repo.get_by(id: tip_id)
    |> upvote_tip(user)
  end

  def upvote_tip(nil, _user), do: {:error, :not_found}
  def upvote_tip(_tip, nil), do: {:error, :not_found}
  def upvote_tip(%{contributor_id: user_id}, %{id: user_id}), do: {:ok, nil}
  def upvote_tip(tip, user) do
    %Upvote{}
    |> Upvote.changeset(%{user_id: user.id, tip_id: tip.id})
    |> Repo.insert()
    |> case do
      {:ok, _} ->
        {_, [%{upvote_count: count}]} =
          tip.id
          |> Query.where_id()
          |> Query.return([:upvote_count])
          |> Repo.update_all(inc: [upvote_count: 1])
        updated_tip = tip_preloads(%{tip | upvote_count: count})
        PubSub.broadcast(ElixirStream.PubSub, @tip_topic, [:tip, :update, updated_tip])
        {:ok, updated_tip}

      error ->
        error
    end
  end

  @spec tips_upvoted_by_user(%User{}, Keyword.t()) :: list(String.t())
  def tips_upvoted_by_user(user, where_id: tip_ids) do
    Tip
    |> Query.where_ids(tip_ids)
    |> Query.upvoted_by(user.id)
    |> Query.return([:id])
    |> Repo.all()
    |> Enum.map(& &1.id)
    |> IO.inspect(label: "UPVOTED")
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
