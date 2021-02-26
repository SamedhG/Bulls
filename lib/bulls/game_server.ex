defmodule Bulls.GameServer do
  use GenServer

  alias Bulls.BackupAgent
  alias Bulls.Game

  # public interface

  def reg(name) do
    {:via, Registry, {Bulls.GameReg, name}}
  end

  def start(name) do
    spec = %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [name]},
      restart: :permanent,
      type: :worker
    }
    Bulls.GameSup.start_child(spec)
  end

  def start_link(name) do
    game = BackupAgent.get(name) || Game.new
    GenServer.start_link(
      __MODULE__,
      game,
      name: reg(name)
    )
  end

  def reset(name) do
    GenServer.call(reg(name), {:reset, name})
  end

  def guess(name, player, guess) do
    GenServer.call(reg(name), {:guess, name, player, guess})
  end

  def add_player(name, player) do
    GenServer.call(reg(name), {:add_player, name, player})
  end
 
  def ready(name, player) do
    GenServer.call(reg(name), {:ready, name, player})
  end

  def peek(name) do
    GenServer.call(reg(name), {:peek, name})
  end
  

  # implementation

  def init(game) do
    {:ok, game}
  end

  # TODO: Maybe reset should keep the players in the game
  def handle_call({:reset, name}, _from, game) do
    game = Game.reset(game)
    BackupAgent.put(name, game)
    update_view(game, name)
    {:reply, game, game}
  end

  ## TODO: these should be abstracted out
  def handle_call({:guess, name, player, guess}, _from, game) do
    case Game.guess(game, player, guess) do
      { :ok, game } -> 
        BackupAgent.put(name, game)
        {:reply, {:ok, game}, game}
      { :error, msg } ->
        {:reply, {:error, msg},  game }
    end
  end

  def handle_call({:add_player, name, player}, _from, game) do
    case Game.add_player(game, player) do
      { :ok, game } -> 
        BackupAgent.put(name, game)
        update_view(game, name)
        {:reply, {:ok, game}, game}
      { :error, msg } ->
        {:reply, {:error, msg},  game }
    end
  end

  # TODO: fire off a send_after if the returned view has the status "ongoing"
  def handle_call({:ready, name, player}, _from, game) do
    case Game.ready(game, player) do
      { :ok, game } ->
        BackupAgent.put(name, game)
        update_view(game, name)
        if game.started do
          Process.send_after(self(), {:commit, name}, 30_000)
        end
        {:reply, {:ok, game}, game}
      { :error, msg } ->
        {:reply, {:error, msg},  game }
    end
  end

  def handle_call({:peek, name}, _from, game) do
    {:reply, Map.put(game, :name, name), game}
  end

  def handle_info({:commit, name}, game) do
    {:ok, game}  = Game.commit(game)
    update_view(game, name)
    if game.started do
      Process.send_after(self(), {:commit, name}, 30_000)
    end
    {:noreply, game}
  end

  defp update_view(game, name) do
    BullsWeb.Endpoint.broadcast!(
      "game:1",
      "view",
      game |> Game.view |> Map.put(:name, name))
  end
end
