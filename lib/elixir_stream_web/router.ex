defmodule ElixirStreamWeb.Router do
  use ElixirStreamWeb, :router
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug ElixirStreamWeb.GuardianPipeline
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

  pipeline :robots do
    plug :accepts, ~w[json txt xml webmanifest]
  end

  scope "/", ElixirStreamWeb, log: false do
    pipe_through [:robots]

    get "/sitemap.xml", RobotController, :sitemap
    get "/robots.txt", RobotController, :robots
    get "/rss.xml", RobotController, :rss
    get "/site.webmanifest", RobotController, :site_webmanifest
    get "/browserconfig.xml", RobotController, :browserconfig
  end

  scope "/auth", ElixirStreamWeb do
    pipe_through [:browser]
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/", ElixirStreamWeb do
    pipe_through :browser

    live "/", PageLive, :index

    get "/about", PageController, :about

    get "/logout", AuthController, :delete
    delete "/logout", AuthController, :delete
    live "/profile", ProfileLive, :edit

    live "/tips", TipLive, :index
    live "/tips/new", TipLive, :new
    live "/tips/:id", TipLive, :show
    live "/tips/:id/edit", TipLive, :edit
  end

  scope "/admin", as: :admin do
    pipe_through [:browser, :require_admin]

    live_dashboard "/dashboard",
      metrics: ElixirStreamWeb.Telemetry,
      ecto_repos: [ElixirStream.Repo]
  end

  if Mix.env() == :dev do
    forward "/sent_emails", Bamboo.SentEmailViewerPlug
  end

  defp is_admin(conn, _opts) do
    user = Guardian.Plug.current_resource(conn)

    if ElixirStream.Accounts.admin?(user) do
      conn
    else
      conn
      |> redirect(to: "/")
      |> halt()
    end
  end
end
