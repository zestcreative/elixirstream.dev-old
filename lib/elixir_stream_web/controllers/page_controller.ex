defmodule ElixirStreamWeb.PageController do
  use ElixirStreamWeb, :controller

  def about(conn, _params) do
    render(conn, "about.html")
  end
end
