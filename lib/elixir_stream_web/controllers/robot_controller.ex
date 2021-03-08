defmodule ElixirStreamWeb.RobotController do
  use ElixirStreamWeb, :controller

  @sizes [
    [name: "favicon", size: "16x16", density: "0.50"],
    [name: "favicon", size: "32x32", density: "0.75"],
    [name: "android-chrome", size: "192x192", density: "1.0"],
    [name: "android-chrome", size: "512x512", density: "2.0"]
  ]

  @endpoint %Plug.Conn{private: %{phoenix_static_url: URI.parse("https://elixirstream.dev")}}

  @manifest %{
    name: "Elixir Stream",
    short_name: "Elixir Stream",
    icons:
      for [name: name, size: size, density: density] <- @sizes do
        %{
          src: Routes.static_url(@endpoint, "/images/#{name}-#{size}.png"),
          sizes: size,
          density: density,
          type: "image/png"
        }
      end,
    theme_color: "#270642",
    display: "minimal-ui",
    background_color: "#270642"
  }

  def robots(conn, _params) do
    conn
    |> put_resp_content_type("text/plain")
    |> render("robots.txt", %{env: Application.get_env(:elixir_stream, :app_env)})
  end

  def site_webmanifest(conn, _params) do
    json(conn, @manifest)
  end

  def browserconfig(conn, _params) do
    conn
    |> put_resp_content_type("application/xml")
    |> render("browserconfig.xml", %{conn: conn})
  end
end
