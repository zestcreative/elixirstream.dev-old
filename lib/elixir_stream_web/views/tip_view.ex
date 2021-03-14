defmodule ElixirStreamWeb.TipView do
  use ElixirStreamWeb, :view
  import ElixirStream.Accounts, only: [admin?: 1]

  def show_edit?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_edit?(_tip, current_user), do: admin?(current_user)

  def show_approve?(%{approved: true}, _current_user), do: false
  def show_approve?(_tip, current_user), do: admin?(current_user)

  def show_delete?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_delete?(_tip, current_user), do: admin?(current_user)
end
