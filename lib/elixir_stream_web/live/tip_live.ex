defmodule ElixirStreamWeb.TipLive do
  use ElixirStreamWeb, :live_view
  use Ecto.Schema
  alias Ecto.Changeset
  alias ElixirStream.Catalog
  require Logger

  @placeholder """
  defmodule Tip do
    def hello(arg) do
      IO.puts("Hello " <> arg)
    end
  end

  # iex> Tip.hello("world")
  # => "Hello world"
  # iex> :ok
  """

  embedded_schema do
    field :title, :string
    field :description, :string
    field :code, :string, default: @placeholder
    field :published_at, :string
  end

  @limit 1024 * 5
  def changeset(tip \\ %__MODULE__{}, attrs) do
    tip
    |> Changeset.cast(attrs, ~w[title description code published_at]a)
    |> Changeset.validate_required(~w[title description published_at]a)
    |> Changeset.validate_length(:code, max: @limit)
    |> Changeset.validate_length(:description, min: 20, max: 200)
    |> Changeset.validate_length(:title, max: 50)
  end

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ElixirStream.PubSub, "tips")
    end

    {:ok,
      socket
      |> mount_new_tip()
      |> assign_defaults()
      |> load_user(session)
    }
  end

  @impl true
  def handle_event("validate", %{"tip_live" => params}, socket) do
    {:noreply, assign(socket, changeset: changeset(socket.assigns.tip, params))}
  end

  def handle_event("save", %{"tip_live" => params}, socket) do
    params = Map.put(params, "contributor_id", socket.assigns.current_user.id)
    with changeset <- changeset(socket.assigns.tip, params),
         {:ok, _tip} <- Changeset.apply_action(changeset, :insert),
         {:ok, published_at} <- Date.from_iso8601(params["published_at"]),
         published_at <- Map.merge(DateTime.utc_now(), Map.from_struct(published_at)),
         {:ok, _tip} <- params |> Map.put("published_at", published_at) |> Catalog.create_tip() do
      {:noreply,
        socket
        |> mount_new_tip()
        |> put_flash(:info, gettext("Successfully scheduled tip. Thank you so much for your contribution!"))
        |> push_patch(to: Routes.tip_path(socket, :index))}
    else
      {:error, date_error} when date_error in ~w[invalid_date invalid_format]a ->
        {:noreply, assign(socket, :changeset, Changeset.add_error(socket.assigns.changeset, :published_at, "is invalid"))}
      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("upvote-tip", %{"tip-id" => tip_id}, socket) do
    Catalog.upvote_tip(tip_id, socket.assigns.current_user)
    {:noreply, socket}
  end
  def handle_event("upvote-tip", _, socket), do: {:noreply, socket}

  def handle_event("downvote-tip", %{"tip-id" => tip_id}, socket) do
    Catalog.downvote_tip(tip_id, socket.assigns.current_user)
    {:noreply, socket}
  end
  def handle_event("downvote-tip", _, socket), do: {:noreply, socket}

  def handle_event("code-updated", "", socket), do: handle_event("code-updated", nil, socket)
  def handle_event("code-updated", code, socket) do
    params = Map.merge(socket.assigns.changeset.params, %{"code" => code})
    {:noreply, assign(socket, :changeset, changeset(socket.assigns.changeset, params))}
  end

  def handle_event("preview", _params, socket) do
    socket.assigns.changeset
    |> Changeset.apply_changes()
    |> Catalog.generate_codeshot()
    |> case do
      {:ok, url} ->
        {:noreply,
          socket
          |> assign(:preview_image_url, url)
          |> push_event(:preview, %{imgUrl: url})}
      {:error, error} ->
        Logger.error(inspect(error))
        {:noreply, socket}
    end
  end

  def handle_event("search", %{"search" => search}, socket) do
    to  = Routes.tip_path(socket, :index, %{"search" => search})
    {:noreply, socket |> push_patch(to: to)}
  end

  @impl true
  def handle_info([:tip, _action, _tip], %{assigns: %{searching: true}} = socket), do: {:noreply, socket}
  def handle_info([:tip, _action, _tip], socket), do: {:noreply, socket}
  def handle_info([:tip, :approve, tip], socket), do: {:noreply, assign(socket, tips: [tip | socket.assigns.tips])}
  def handle_info([:tip, :update, %{id: tip_id} = updated_tip], socket) do
    socket = load_my_upvotes(socket)
    tips =
      Enum.map(
        socket.assigns.tips,
        fn
          %{id: ^tip_id} -> updated_tip
          tip -> tip
        end
      )

    {:noreply, assign(socket, tips: tips)}
  end

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    case Catalog.find_tip(id) do
      nil ->
        {:noreply,
          socket
          |> put_flash(:error, gettext("Tip not found"))
          |> push_redirect(to: Routes.tip_path(socket, :index))}
      tip ->
        {:noreply, assign(socket, :tip, tip)}
    end
  end

  def handle_params(%{"search" => %{"q" => ""}}, _uri, socket) do
    {:noreply, socket |> assign(:searching, false) |> push_patch(to: Routes.tip_path(socket, :index))}
  end
  def handle_params(%{"search" => params}, _uri, socket) do
    search_changeset = search_changeset(params)

    case Changeset.apply_action(search_changeset, :insert) do
      {:ok, %{q: q}} ->
        {:noreply, assign(socket, search_changeset: search_changeset, searching: true, tips: Catalog.search_tips(q))}

      {:error, search_changeset} ->
        {:noreply, assign(socket, search_changeset: search_changeset)}
    end
  end

  def handle_params(params, _uri, socket) do
    {:noreply, socket
    |> load_tips(params)
    |> assign(search_changeset: search_changeset(%{}))}
  end

  defp mount_new_tip(socket) do
    tip = %__MODULE__{}
    changeset = changeset(tip, %{published_at: Date.utc_today() |> Date.to_iso8601()})
    placeholder_code = Changeset.get_field(changeset, :code)
    socket
    |> assign(:tip, tip)
    |> assign(:preview_image_url, nil)
    |> assign(:changeset, changeset)
    |> push_event(:set_code, %{code: placeholder_code})
  end

  defp load_tips(socket, %{"sort" => "popular"}) do
    socket
    |> assign(tips: Catalog.list_tips(:popular))
    |> load_my_upvotes()
  end
  defp load_tips(socket, _) do
    socket
    |> assign(tips: Catalog.list_tips(:latest))
    |> load_my_upvotes()
  end

  defp load_my_upvotes(socket) do
    if user = socket.assigns[:current_user] do
      tip_ids = Enum.map(socket.assigns.tips, & &1.id)
      assign(socket, :upvoted_tip_ids, Catalog.tips_upvoted_by_user(user, where_id: tip_ids))
    else
      socket
    end
  end
end
