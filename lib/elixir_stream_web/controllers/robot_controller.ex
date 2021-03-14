defmodule ElixirStreamWeb.RobotController do
  use ElixirStreamWeb, :controller
  require Logger
  alias ElixirStream.Catalog

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

  def rss(conn, _params) do
    conn = conn |> put_resp_content_type("application/xml") |> send_chunked(200)

    with {:ok, conn} <- chunk(conn, rss_header(conn)),
         {:ok, conn} <-
           stream_tips(conn, Catalog.list_tips(by_latest: true, stream: true, max_rows: 100)),
         {:ok, conn} <- chunk(conn, rss_footer()) do
      conn
    else
      {:error, reason} ->
        Logger.error("RSS tip chunking failed: #{inspect(reason)}")
        conn
    end
  end

  def site_webmanifest(conn, _params) do
    json(conn, @manifest)
  end

  def browserconfig(conn, _params) do
    conn
    |> put_resp_content_type("application/xml")
    |> render("browserconfig.xml", %{conn: conn})
  end

  defp format_date(%{published_at: date}), do: format_date(date)

  defp format_date(%DateTime{} = date) do
    Calendar.strftime(date, "%a, %d %b %Y %H:%M:%S %z")
  end

  defp stream_tips(conn, stream) do
    ElixirStream.Repo.transaction(fn ->
      Enum.reduce_while(stream, conn, fn tip, conn ->
        case chunk(conn, rss_tip(conn, tip)) do
          {:ok, conn} ->
            {:cont, conn}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)
    end)
  end

  defp rss_header(conn) do
    seo = %ElixirStreamWeb.Seo.Generic{}

    [
      ~s|<?xml version="1.0" encoding="UTF-8"?>\n|,
      ~s|<rss xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:content="http://purl.org/rss/1.0/modules/content/" xmlns:atom="http://www.w3.org/2005/Atom" version="2.0">\n|,
      "<channel>\n",
      ~s|<atom:link href="#{Routes.robot_url(conn, :rss)}" rel="self" type="application/rss+xml" />\n|,
      "<title>#{cdata(seo.title)}</title>\n",
      "<language>#{seo.language}</language>\n",
      "<description>#{cdata(seo.description)}</description>\n",
      "<pubDate>#{format_date(DateTime.utc_now())}</pubDate>\n",
      "<link>#{Routes.page_url(conn, :index)}</link>\n",
      "<copyright>Copyright #{Date.utc_today().year} #{seo.author}</copyright>\n",
      "<generator>Artisinally Crafted by Yours Truly</generator>\n"
    ]
  end

  defp rss_tip(conn, tip) do
    [
      "<item>\n",
      "<title>#{cdata(tip.title)}</title>\n",
      "<dc:creator>#{tip.contributor.name}</dc:creator>\n",
      "<description>#{cdata(tip.description)}</description>\n",
      "<link>#{Routes.tip_url(conn, :show, tip.id)}</link>\n",
      "<guid isPermaLink=\"true\">#{Routes.tip_url(conn, :show, tip.id)}</guid>\n",
      "<pubDate>#{format_date(tip)}</pubDate>\n",
      "<content:encoded>#{tip |> rss_tip_body() |> cdata()}</content:encoded>\n",
      "</item>\n"
    ]
  end

  defp rss_tip_body(%{description: description, code: code}) do
    [description, "\n\n<pre><code>", code, "</code></pre>\n"]
  end

  defp rss_footer(), do: ["</channel>\n", "</rss>\n"]

  defp cdata(content), do: "<![CDATA[#{content}]]>"
end
