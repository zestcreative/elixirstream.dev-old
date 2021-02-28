defmodule ElixirStreamWeb.Router do
  use ElixirStreamWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :current_user
    plug :put_root_layout, {ElixirStreamWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :require_admin do
    plug :is_admin
  end

  scope "/auth", ElixirStreamWeb do
    pipe_through [:browser]
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/", ElixirStreamWeb do
    pipe_through :browser

    live "/", PageLive, :index
    get "/logout", AuthController, :delete
    delete "/logout", AuthController, :delete
  end

  scope "/admin", as: :admin do
    pipe_through [:browser, :require_admin]
    live_dashboard "/dashboard", metrics: ElixirStreamWeb.Telemetry
  end

  def current_user(conn, _opts) do
    Plug.Conn.assign(
      conn,
      :current_user,
      Plug.Conn.get_session(conn, :current_user)
    )
  end

  defp is_admin(conn, _opts) do
    if ElixirStreamWeb.UserFromAuth.admin?(conn.assigns.current_user) do
      conn
    else
      conn
      |> send_resp(401, "Go away")
      |> halt()
    end
  end
end
