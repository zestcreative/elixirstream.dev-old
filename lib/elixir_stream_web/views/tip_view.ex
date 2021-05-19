defmodule ElixirStreamWeb.TipView do
  use ElixirStreamWeb, :view
  import ElixirStream.Accounts, only: [admin?: 1]

  def max_characters, do: ElixirStreamWeb.TipLive.character_limit()

  def show_edit?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_edit?(_tip, current_user), do: admin?(current_user)

  def show_approve?(%{approved: true}, _current_user), do: false
  def show_approve?(_tip, current_user), do: admin?(current_user)

  def show_delete?(%{contributor_id: user_id}, %{id: user_id}), do: true
  def show_delete?(_tip, current_user), do: admin?(current_user)

  @warning_threshold_below_max 20
  def color_for_bar(count, max_count) when count > max_count do
    {"bg-red-200", "bg-red-500"}
  end

  def color_for_bar(count, max_count) do
    if count > max_count - @warning_threshold_below_max do
      {"bg-yellow-200", "bg-yellow-500"}
    else
      {"bg-brand-200", "bg-brand-500"}
    end
  end
end
