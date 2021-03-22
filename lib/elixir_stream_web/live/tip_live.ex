defmodule ElixirStreamWeb.TipLive do
  use ElixirStreamWeb, :live_view
  use Ecto.Schema
  import ElixirStream.Accounts, only: [admin?: 1]
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
    field :code_image_url, :string
    field :published_at, :string
    field :contributor, :any, virtual: true
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
     |> assign_defaults(session)
     |> mount_new_tip()}
  end

  @impl true
  def handle_event("validate", %{"tip_live" => params}, socket) do
    {:noreply, assign(socket, changeset: changeset(socket.assigns.tip_form, params))}
  end

  def handle_event("create", %{"tip_live" => params}, socket) do
    params = Map.put(params, "contributor_id", socket.assigns.current_user.id)

    with changeset <- changeset(socket.assigns.tip_form, params),
         {:ok, _tip} <- Changeset.apply_action(changeset, :insert),
         {:ok, published_at} <- Date.from_iso8601(params["published_at"]),
         published_at <- Map.merge(DateTime.utc_now(), Map.from_struct(published_at)),
         {:ok, _tip} <- params |> Map.put("published_at", published_at) |> Catalog.create_tip() do
      {:noreply,
       socket
       |> mount_new_tip()
       |> put_flash(
         :info,
         gettext("Successfully scheduled tip. Thank you so much for your contribution!")
       )
       |> push_patch(to: Routes.tip_path(socket, :index))}
    else
      {:error, date_error} when date_error in ~w[invalid_date invalid_format]a ->
        {:noreply,
         assign(
           socket,
           :changeset,
           Changeset.add_error(socket.assigns.changeset, :published_at, "is invalid")
         )}

      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("update", %{"tip_live" => params}, socket) do
    with {:ok, _tip} <-
           socket.assigns.tip_form |> changeset(params) |> Changeset.apply_action(:update),
         {:ok, _tip} <-
           Catalog.update_tip(socket.assigns.tip, unapprove_if_not_admin(params, socket)) do
      {:noreply,
       socket
       |> mount_new_tip()
       |> put_flash(:info, gettext("Updated tip."))
       |> push_patch(to: Routes.tip_path(socket, :index))}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
  end

  def handle_event("approve-tip", %{"tip-id" => tip_id}, socket) do
    if admin?(socket.assigns.current_user) do
      Catalog.approve_tip(tip_id)
    end

    {:noreply, socket}
  end

  def handle_event("delete-tip", %{"tip-id" => tip_id}, socket) do
    {:noreply,
     case Catalog.delete_tip_for_user(tip_id, socket.assigns.current_user) do
       {:ok, %{id: id}} ->
         socket
         |> assign(tips: Enum.reject(socket.assigns.tips, &(&1.id == id)))

       _ ->
         socket
     end}
  end

  def handle_event("next-page", _, socket) do
    %{entries: tips, metadata: metadata} =
      socket
      |> tip_opts(socket.assigns.tip_sort ++ [after: socket.assigns.page_metadata.after])
      |> Catalog.list_tips()

    {:noreply,
     socket
     |> push_event(:scroll, %{selector: "#top-pagination-nav"})
     |> assign(tips: tips)
     |> assign(page_metadata: metadata)}
  end

  def handle_event("prev-page", _, socket) do
    %{entries: tips, metadata: metadata} =
      socket
      |> tip_opts(socket.assigns.tip_sort ++ [before: socket.assigns.page_metadata.before])
      |> Catalog.list_tips()

    {:noreply,
     socket
     |> push_event(:scroll, %{selector: "#top-pagination-nav"})
     |> assign(tips: tips)
     |> assign(page_metadata: metadata)}
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
      {:ok, %{code_image_url: url}, _file} ->
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
    to = Routes.tip_path(socket, :index, %{"search" => search})
    {:noreply, socket |> push_patch(to: to)}
  end

  @impl true
  def handle_info([:tip, _action, _tip], %{assigns: %{searching: true}} = socket),
    do: {:noreply, socket}

  def handle_info([:tip, action, %{id: tip_id} = updated_tip], socket)
      when action in ~w[update approve]a do
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

  def handle_info([:tip, _action, _tip], socket), do: {:noreply, socket}

  @impl true
  def handle_params(%{"id" => id}, _uri, socket) do
    case Catalog.find_tip(id) do
      nil ->
        {:noreply,
         socket
         |> put_flash(:error, gettext("Tip not found"))
         |> push_redirect(to: Routes.tip_path(socket, :index))}

      tip ->
        tip_form = %__MODULE__{
          contributor: tip.contributor,
          title: tip.title,
          description: tip.description,
          code: tip.code,
          published_at: tip.published_at |> DateTime.to_date() |> Date.to_iso8601()
        }

        {:noreply,
         socket
         |> load_my_upvotes(tip)
         |> assign(:tip, tip)
         |> assign(:tip_form, tip_form)
         |> assign(:page_title, tip.title)
         |> assign(:changeset, changeset(tip_form, %{}))}
    end
  end

  def handle_params(%{"search" => %{"q" => ""}}, _uri, socket) do
    {:noreply,
     socket
     |> assign(:searching, false)
     |> push_patch(to: Routes.tip_path(socket, :index))}
  end

  def handle_params(%{"search" => params}, _uri, socket) do
    search_changeset = search_changeset(params)

    case Changeset.apply_action(search_changeset, :insert) do
      {:ok, %{q: q}} ->
        {:noreply,
         socket
         |> load_tips(search: q, by_latest: true)
         |> assign(:search_changeset, search_changeset)
         |> assign(:searching, true)}

      {:error, search_changeset} ->
        {:noreply, assign(socket, search_changeset: search_changeset)}
    end
  end

  def handle_params(params, _uri, %{assigns: %{live_action: :new}} = socket) do
    {:noreply,
     socket
     |> mount_new_tip()
     |> assign(tips: [])
     |> assign(page_metadata: nil)
     |> assign(search_changeset: search_changeset(params))}
  end

  def handle_params(params, _uri, socket) do
    {:noreply,
     socket
     |> load_tips(params)
     |> assign(search_changeset: search_changeset(params))}
  end

  defp mount_new_tip(socket) do
    tip = %__MODULE__{contributor: socket.assigns.current_user}
    changeset = changeset(tip, %{published_at: Date.utc_today() |> Date.to_iso8601()})
    placeholder_code = Changeset.get_field(changeset, :code)

    socket
    |> assign(:tip_form, tip)
    |> assign(:preview_image_url, nil)
    |> assign(page_title: "New tip")
    |> assign(:changeset, changeset)
    |> push_event(:set_code, %{code: placeholder_code})
  end

  defp load_tips(socket, %{"sort" => "popular"}) do
    socket
    |> load_tips(by_upvotes: true)
    |> assign(:page_title, "Popular Tips")
  end

  defp load_tips(socket, params) when is_map(params) do
    socket
    |> load_tips(by_latest: true)
    |> assign(:page_title, "Latest Tips")
  end

  defp load_tips(socket, opts) when is_list(opts) do
    %{entries: tips, metadata: metadata} = socket |> tip_opts(opts) |> Catalog.list_tips()

    socket
    |> assign(tips: tips)
    |> assign(tip_sort: opts)
    |> assign(page_metadata: metadata)
    |> load_my_upvotes()
  end

  defp tip_opts(socket, opts) do
    if admin?(socket.assigns.current_user) do
      Keyword.merge(
        [paginate: true, unpublished: true, by_not_approved: true, not_approved: true],
        opts
      )
    else
      Keyword.merge([paginate: true, unpublished: socket.assigns.current_user.id], opts)
    end
  end

  defp load_my_upvotes(socket, tip) do
    assign(
      socket,
      :upvoted_tip_ids,
      Catalog.tips_upvoted_by_user(socket.assigns[:current_user], where_id: [tip.id])
    )
  end

  defp load_my_upvotes(socket) do
    tip_ids = Enum.map(socket.assigns.tips, & &1.id)

    assign(
      socket,
      :upvoted_tip_ids,
      Catalog.tips_upvoted_by_user(socket.assigns[:current_user], where_id: tip_ids)
    )
  end

  defp unapprove_if_not_admin(params, socket) do
    if admin?(socket.assigns.current_user) do
      params
    else
      Map.put(params, "approved", false)
    end
  end
end
