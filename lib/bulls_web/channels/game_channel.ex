defmodule BullsWeb.GameChannel do
  alias Bulls.Game

  use BullsWeb, :channel

  @impl true
  def join("game:" <> _id, payload, socket) do
    if authorized?(payload) do
      game = Game.new()
      socket = assign(socket, :game, game)
      view = Game.view(game)
      {:ok, view, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("guess", guess, socket) do
    game0 = socket.assigns[:game]
    case Game.guess(game0, guess) do
      {:ok, game1} -> 
        socket = assign(socket, :game, game1)
        view = Game.view(game1)
        {:reply, {:ok, view}, socket}
      {:error, msg} ->
        {:reply, {:error, %{ message: msg }}, socket}
    end
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (game:lobby).
  @impl true
  def handle_in("reset", _payload, socket) do
      game = Game.new()
      socket = assign(socket, :game, game)
      view = Game.view(game)
      {:reply, {:ok, view}, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end
end
