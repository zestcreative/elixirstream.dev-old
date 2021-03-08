defmodule ElixirStreamWeb.ProfileLive do
  use ElixirStreamWeb, :live_view
  alias ElixirStream.Accounts

  @impl true
  def mount(_params, session, socket) do
    require_user(socket, session)
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
end
