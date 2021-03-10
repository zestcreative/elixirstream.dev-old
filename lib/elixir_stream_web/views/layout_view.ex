defmodule ElixirStreamWeb.LayoutView do
  use ElixirStreamWeb, :view
  import ElixirStream.Accounts, only: [admin?: 1]

  @doc """
  A shim for Phoenix.HTML.Link.link, but adding a class if currently on the page and picking the best LiveView link
  helper (live_patch vs live_redirect vs link). Integrated with AlpineJS.
  """
  def active_link(conn, route, text, opts)

  def active_link(conn, route, opts, do: contents) when is_list(opts) do
    active_link(conn, route, contents, opts)
  end

  def active_link(%Phoenix.LiveView.Socket{} = socket, route, text, opts) do
    to = opts |> Keyword.fetch!(:to) |> String.split("?") |> hd()
    destination_info = Phoenix.Router.route_info(socket.router, "GET", to, socket.endpoint.host)
    liveview_opts = [
            "@click": "$dispatch('navigate', '#{route}')",
            ":class": "{'active': currentRoute === '#{route}', '': currentRoute !== '#{route}'}"
          ]

    with current_liveview <- socket.view,
         %{phoenix_live_view: {^current_liveview, _action}} <- destination_info do
      Phoenix.LiveView.Helpers.live_patch(text, opts ++ liveview_opts)
    else
      %{phoenix_live_view: _} ->
        Phoenix.LiveView.Helpers.live_redirect(text, opts ++ liveview_opts)
      _ ->
        Phoenix.HTML.Link.link(text, opts)
    end
  end

  def active_link(%Plug.Conn{} = conn, route, text, opts) do
    to = Keyword.fetch!(opts, :to)
    destination_info = Phoenix.Router.route_info(conn.private[:phoenix_router], "GET", to, conn.host)
    liveview_opts = [
            "@click": "$dispatch('navigate', '#{route}')",
            ":class": "{'active': currentRoute === '#{route}', '': currentRoute !== '#{route}'}"
          ]

    with {current_liveview, _opts} <- conn.private[:phoenix_live_view],
         %{phoenix_live_view: {^current_liveview, _action}} <- destination_info do
      Phoenix.LiveView.Helpers.live_patch(text, opts ++ liveview_opts)
    else
      %{phoenix_live_view: _} ->
        Phoenix.LiveView.Helpers.live_redirect(text, opts ++ liveview_opts)
      _ ->
        Phoenix.HTML.Link.link(text, opts)
    end
  end

  def current_alpine_route(%Plug.Conn{} = conn) do
    Enum.join(conn.path_info || ["/"], "-")
  end
  def current_alpine_route(%Phoenix.LiveView.Socket{} = _socket) do
    nil
  end
end
