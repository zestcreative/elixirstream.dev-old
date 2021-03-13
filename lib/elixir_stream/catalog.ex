defmodule ElixirStream.Catalog do
  alias ElixirStream.Catalog.{Query, Tip, Upvote}
  alias ElixirStream.Accounts.{User}
  alias ElixirStream.{Silicon, Storage, Repo}
  alias Phoenix.PubSub
  require Ecto.Query

  @tip_topic "tips"

  @spec find_tip(String.t()) :: nil | %Tip{}
  def find_tip(id) do
    Tip
    |> Query.preload_contributor()
    |> Repo.get(id)
  end

  @type tip_queryable :: :latest | :popular | Ecto.Queryable.t()

  @spec search_tips(String.t()) :: list(%Tip{})
  def search_tips(search_terms, opts \\ []) do
    Tip
    |> Query.preload_contributor()
    |> Query.search(search_terms)
    |> list_tips(opts)
  end

  @spec list_tips(tip_queryable, Keyword.t()) :: list(%Tip{})
  def list_tips(shorthand, opts \\ [])

  def list_tips(:latest, opts) do
    Tip
    |> Query.preload_contributor()
    |> Query.order_by_latest()
    |> list_tips(opts)
  end

  def list_tips(:popular, opts) do
    Tip
    |> Query.preload_contributor()
    |> Query.order_by_upvotes()
    |> list_tips(opts)
  end

  def list_tips(:unapproved, opts) do
    Tip
    |> Query.preload_contributor()
    |> Query.unapproved()
    |> list_tips(opts)
  end

  def list_tips(queryable, opts) do
    queryable =
      if limit = Keyword.get(opts, :limit, false),
        do: Ecto.Query.limit(queryable, ^limit),
        else: queryable

    queryable =
      if order = Keyword.get(opts, :order, false),
        do: Ecto.Query.order_by(queryable, ^order),
        else: queryable

    queryable =
      if Keyword.get(opts, :paginate, false), do: paginate_tips(queryable, opts), else: queryable

    queryable =
      if Keyword.get(opts, :unapproved, false), do: queryable, else: Query.approved(queryable)

    queryable =
      case Keyword.get(opts, :unpublished, false) do
        id when is_binary(id) -> Query.where_mine_or_published(queryable, id)
        false -> Query.where_published(queryable)
        true -> queryable
      end

    Repo.all(queryable)
  end

  def paginate_tips(queryable, opts \\ []) do
    Repo.paginate(queryable, opts)
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
  def tips_upvoted_by_user(nil, _opts), do: []
  def tips_upvoted_by_user(%{id: nil}, _opts), do: []

  def tips_upvoted_by_user(user, where_id: tip_ids) do
    Tip
    |> Query.where_ids(tip_ids)
    |> Query.upvoted_by(user.id)
    |> Query.return([:id])
    |> Repo.all()
    |> Enum.map(& &1.id)
  end

  @spec add_image_to_tip(%Tip{}, String.t()) :: {:ok, %Tip{}} | {:error, Ecto.Changeset.t()}
  def add_image_to_tip(%{id: nil} = tip, key) do
    case Storage.url(key, expires_in: :timer.minutes(5), grant_read: :public_read) do
      {:ok, url} -> {:ok, %{tip | code_image_url: url}}
      error -> error
    end
  end

  def add_image_to_tip(%{id: id} = tip, key) when is_binary(id) do
    tip
    |> Tip.changeset(%{code_image_url: key})
    |> Repo.update()
  end

  def add_twitter_status_id(tip, twitter_status_id) do
    tip
    |> Tip.changeset(%{twitter_status_id: twitter_status_id})
    |> Repo.update()
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

  @spec update_tip(%Tip{}, map()) :: {:ok, %Tip{}} | {:error, Ecto.Changeset.t()}
  def update_tip(tip, attrs) do
    tip
    |> Tip.changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, tip} ->
        tip = tip_preloads(tip)
        PubSub.broadcast(ElixirStream.PubSub, @tip_topic, [:tip, :update, tip])
        {:ok, tip}

      error ->
        error
    end
  end

  @spec approve_tip(%Tip{}) :: {:ok, %Tip{}}
  def approve_tip(tip_id) when is_binary(tip_id), do: tip_id |> find_tip() |> approve_tip()

  def approve_tip(tip) do
    with {:ok, tip} <- tip |> Tip.changeset(%{approved: true}) |> Repo.update(),
         {:ok, _} <-
           %{tip_id: tip.id}
           |> ElixirStream.Workers.PublishTip.new(scheduled_at: tip.published_at)
           |> Oban.insert() do
      tip = tip_preloads(tip)
      PubSub.broadcast(ElixirStream.PubSub, @tip_topic, [:tip, :approve, tip])
      {:ok, tip}
    else
      error ->
        error
    end
  end

  @codeshot_upload_folder "codeshots"
  def generate_codeshot(tip) do
    with {:ok, file} <- Silicon.generate(tip),
         tmp_id <- Path.basename(file),
         {:ok, %{body: %{key: key}}} <-
           Storage.upload(file, Path.join(@codeshot_upload_folder, tip.id || tmp_id)),
         {:ok, tip} <- add_image_to_tip(tip, key) do
      {:ok, tip, file}
    end
  end
end
