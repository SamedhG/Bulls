defmodule BullsWeb.GameChannel do
  use BullsWeb, :channel

  alias Bulls.Game
  alias Bulls.GameServer

  @impl true
  def join("game:1", _payload, socket) do
    socket = socket
             |> assign(:name, "")
             |> assign(:user, "")
    {:ok, %{}, socket}
  end


  @impl true
  def handle_in("login", %{ "user" => user, "name" => name, "observer" => observer }, socket) do
    GameServer.start(name)
    if observer do
        game = GameServer.peek(name)
        socket = socket
                 |> assign(:name, name)
                 |> assign(:user, user)
        view = Map.put Game.view(game), :user, user 
        {:reply, {:ok, view}, socket}
    else
        case GameServer.add_player(name, user) do
          { :ok, game } -> 
            socket = socket
                     |> assign(:name, name)
                     |> assign(:user, user)
            view = Map.put Game.view(game), :user, user 
            {:reply, {:ok, view}, socket}
          { :error, msg } -> {:reply,  { :error, %{message: msg} }, socket }
        end
    end
  end

  @impl true
  def handle_in("ready", _payload, socket) do
    user = socket.assigns[:user]
    name = socket.assigns[:name]
    case GameServer.ready(name, user) do
      {:ok, game} -> 
        socket = assign(socket, :game, game)
        view = game |> Game.view |> Map.put(:user, user) |> Map.put(:name, name)
        {:reply, {:ok, view}, socket}
      {:error, msg} ->
        {:reply, {:error, %{ message: msg }}, socket}
    end
  end

  @impl true
  def handle_in("guess", guess, socket) do
    user = socket.assigns[:user]
    name = socket.assigns[:name]
    case GameServer.guess(name, user, guess) do
      {:ok, game} -> 
        socket = assign(socket, :game, game)
        view = game |> Game.view |> Map.put(:user, user) |> Map.put(:name, name)
        {:reply, {:ok, view}, socket}
      {:error, msg} ->
        {:reply, {:error, %{ message: msg }}, socket}
    end
  end

  @impl true
  def handle_in("reset", _payload, socket) do
    name = socket.assigns[:name]
    GameServer.reset(name)
    {:noreply, socket}
  end

  intercept ["view"]

  @impl true
  def handle_out("view", msg, socket) do
    user = socket.assigns[:user]
    name = socket.assigns[:name]
    if name == msg.name do
      push(socket, "view", Map.put(msg, :user, user))
    end
    {:noreply, socket}
  end

end
