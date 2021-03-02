defmodule ElixirStreamWeb.LayoutView do
  use ElixirStreamWeb, :view
  import ElixirStream.Accounts, only: [admin?: 1]
end
