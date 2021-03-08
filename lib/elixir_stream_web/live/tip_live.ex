defmodule ElixirStreamWeb.TipLive do
  use ElixirStreamWeb, :live_view
  use Ecto.Schema
  alias Ecto.Changeset
  alias ElixirStream.{Catalog, Silicon}
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
    field :modules, {:array, :string}
  end

  @limit 1024 * 5
  def changeset(tip \\ %__MODULE__{}, attrs) do
    tip
    |> Changeset.cast(attrs, ~w[title description code published_at modules]a)
    |> Changeset.validate_required(~w[title description]a)
    |> Changeset.validate_length(:code, max: @limit)
    |> Changeset.validate_length(:description, max: @limit)
    |> Changeset.validate_length(:title, max: 200)
  end

  @impl true
  def mount(_params, session, socket) do
    if connected?(socket) do
      Phoenix.PubSub.subscribe(ElixirStream.PubSub, "tips")
    end

    tip = %__MODULE__{}

    {:ok,
      socket
      |> assign(:tip, tip)
      |> load_user(session)
      |> assign(:changeset, changeset(tip, %{})),
      temporary_assigns: [tips: Catalog.list_tips()]
    }
  end

  @impl true
  def handle_event("validate", %{"tip" => params}, socket) do
    IO.puts "HIT"
    {:noreply,
      socket.assigns.tip
      |> changeset(params)
      |> Map.put(:action, :insert)
      |> IO.inspect
      |> case do
        {:ok, tip} ->
          assign(socket, :tip, tip)
        {:error, changeset} ->
          assign(socket, :changeset, changeset)
      end}
  end

  @impl true
  def handle_event("code-updated", code, socket) do
    params =
      Map.merge(
        socket.assigns.changeset.params,
        %{"code" => code}
      )
    {:noreply, assign(socket, :changeset, changeset(socket.assigns.changeset, params))}
  end

  @impl true
  def handle_event("preview", _params, socket) do
    socket.assigns.changeset
    |> Ecto.Changeset.apply_changes()
    |> Silicon.generate()
    |> case do
      {:ok, file} ->
        changeset = Ecto.Changeset.put_change(socket.assigns.changeset, :code_image_url, file)
        {:noreply,
          socket
          |> assign(changeset: changeset)
          |> push_event(:preview, %{imgUrl: file})}
      {:error, error} ->
        Logger.error(error)
        {:noreply, socket}
    end
  end

  @impl true
  def handle_event("save", %{"tip" => params}, socket) do
    with changeset <- changeset(socket.assigns.tip, params),
         {:ok, _tip} <- Changeset.apply_action(changeset, :insert),
         params <- Map.put(params, :contributor_id, socket.assigns.current_user.id),
         {:ok, _tip} <- Catalog.create_tip(params) do
      {:noreply,
        socket
        |> put_flash(:info, gettext("Successfully scheduled tip"))
        |> assign(:tip, %__MODULE__{})}
    else
      {:error, changeset} ->
        {:noreply, assign(socket, :changeset, changeset)}
    end
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
  def handle_params(_index, _uri, socket), do: {:noreply, socket}
end
