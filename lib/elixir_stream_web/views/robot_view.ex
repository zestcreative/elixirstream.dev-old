defmodule ElixirStreamWeb.RobotView do
  use ElixirStreamWeb, :view

  def render("robots.txt", %{env: :prod}) do
    """
    User-agent: *
    Disallow: /admin
    Disallow: /auth
    Disallow: /logout
    Disallow: /profile
    """
  end

  def render("robots.txt", %{env: _}) do
    """
    User-agent: *
    Disallow: /
    """
  end
end
