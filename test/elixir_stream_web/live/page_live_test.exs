defmodule ElixirStreamWeb.PageLiveTest do
  use ElixirStreamWeb.ConnCase

  import Phoenix.LiveViewTest

  test "disconnected and connected render", %{conn: conn} do
    assert {:error, {:redirect, %{to: "/tips"}}} = live(conn, "/")
  end
end
