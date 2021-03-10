defmodule ElixirStreamWeb.ProfileLive do
  use ElixirStreamWeb, :live_view
  alias ElixirStream.Accounts

  @impl true
  def mount(_params, session, socket) do
    socket
    |> assign_defaults()
    |> require_user(session)
  end

  @impl true
  def handle_event("disconnect-twitter", _params, socket) do
    {:noreply,
      case Accounts.update_twitter(socket.assigns.current_user, nil) do
        {:error, _} -> socket
        {:ok, user} -> assign(socket, :current_user, user)
      end
    }
  end

  def handle_event("update-editor-choice", %{"user" => %{"editor" => choice}}, socket) do
    Accounts.update_editor_choice(socket.assigns.current_user, choice)
    {:noreply,
      case Accounts.update_editor_choice(socket.assigns.current_user, choice) do
        {:error, _} -> socket
        {:ok, user} -> assign(socket, :current_user, user)
      end
    }
  end

  def handle_event("search", %{"search" => search}, socket) do
    to  = Routes.tip_path(socket, :index, %{"search" => search})
    {:noreply, socket |> push_redirect(to: to)}
  end
end
