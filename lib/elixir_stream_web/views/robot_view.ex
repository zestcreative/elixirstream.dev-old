defmodule ElixirStreamWeb.RobotView do
  use ElixirStreamWeb, :view

  def render("robots.txt", %{env: :prod}), do: ""

  def render("robots.txt", %{env: _}) do
    """
    User-agent: *
    Disallow: /
    """
  end
end
