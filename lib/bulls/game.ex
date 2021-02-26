defmodule Bulls.Game do

  # Create a new game instance:
  # A Game is one of: 
  #   - { state: :waiting, 
  #       players: {name: ready?}, 
  #       scoreboard: {name : {wins, losses} } }
  #   - { state: :ongoing, 
  #       secret: "some secret", 
  #       guesses: [[]], 
  #       players: [],
  #       current_guesses: []
  #       scoreboard: {name : {wins, losses} } }
  #   - { state: :game_over,
  #       players: {name: win?},
  #       scoreboard: {name : {wins, losses} } }
  def new() do
    %{
      state: :waiting,
      players: %{},
      scoreboard: %{}
    }
  end

  def reset(st) do
    result = %{ state: :waiting, scoreboard: st.scoreboard }
    case st.state do
      :waiting -> Map.put(result, :players, st.players)
      :ongoing -> Map.put(result, :players, Enum.reduce(st.players, %{}, &(Map.put(&2, &1, false))))
      :game_over -> Map.put(result, :players, Map.new(Enum.map(st.players, fn {k, _} -> {k, false} end)))
    end
  end
  ## Prestarting Functionality

  # Add a new player to the game (Upto 4)
  def add_player(st, name) do
    cond do
      st.state != :waiting -> 
        { :error, "Game has already started" }
      st.players |> Map.keys |> length >= 4 ->
        { :error, "Max players of game reached" }
      Map.has_key?(st.players, name) ->
        { :error, "A player with this name is already in the game" }
      true -> { 
          :ok, 
          %{ st | 
            players: Map.put(st.players, name, false),
            scoreboard: Map.put_new(st.scoreboard, name, %{wins: 0, losses: 0})
          }
      }
    end
  end

  def remove_player(st, player) do
    case st.state do
      :ongoing -> {:error, "Cant leave an ongoing game"}
      _ -> {:ok, %{st | players: Map.delete(st.players, player) } }
    end
  end

  # Make a player ready, if all players (atleast 2) are ready game will start
  def ready(st, name) do
    cond do
      st.state != :waiting -> 
        { :error, "Game has already started" }
      !Map.has_key?(st.players, name) ->
        { :error, "You need to join before getting ready" }
      true -> 
        players = Map.put(st.players, name, true)
        if length(Map.keys(players)) >= 2 && Enum.all?(Map.values(players)) do
          players = Map.keys(players)
          { :ok, %{ 
            state: :ongoing, 
            secret: random_secret(),
            guesses: [],
            current_guesses: Enum.map(players, fn _ -> "" end),
            players: players,
            scoreboard: st.scoreboard
          } }
        else
          { :ok, %{ st | players: players } }
        end
    end
  end


  ## During game functionality

  # Make a guess for a player
  def guess(st, player, guess) do
    cond do
      st.state != :ongoing ->  { :error, "Game has not started yet" }
      !Enum.member?(st.players, player) -> { :error, "You are not in this game" }
      true ->
        case validate(st, guess) do
          {:error, msg} -> {:error, msg}
          :ok -> 
            idx = Enum.find_index(st.players, &(&1 == player))
            current_guesses = List.replace_at(st.current_guesses, idx, guess)
            {:ok, %{ st | current_guesses: current_guesses } }
        end
    end
  end


  # Commit the guesses to the game
  def commit(st) do
    cond do
      st.state != :ongoing -> { :error, "Game has not started yet" }
      Enum.member?(st.current_guesses, st.secret) -> 
        results = Map.new(Enum.zip(st.players, 
          Enum.map(st.current_guesses, &(&1 === st.secret))))
        scoreboard = Enum.reduce(results, st.scoreboard, 
          fn {k, v}, acc ->
            if v do 
              %{acc | k=>%{st.scoreboard[k] | wins: st.scoreboard[k].wins + 1 }} 
            else 
              %{acc | k=>%{st.scoreboard[k] | losses: st.scoreboard[k].losses + 1 }} 
            end 
          end)
        {:ok, %{ state: :game_over, scoreboard: scoreboard, players: results}}
      true -> 
        empty = Enum.map(st.players, fn _ -> "" end)
        { :ok, %{ st | 
          guesses: [ st.current_guesses | st.guesses ],
          current_guesses: empty
        } }
    end
  end

  def has_player?(st, player) do
    if st.state == :ongoing do
      Enum.member?(st.players, player)
    else
      Map.has_key?(st.players, player)
    end
  end

  # Checks for the following things:
  # - Repeats in the guess
  # - All digits
  # - Repeats with other guesses
  # - The length should be 4
  # An empty guess represents a PASS
  # returns :ok if valid
  defp validate(st, guess) do 
    cond do
      guess === "" -> :ok
      String.length(guess) != 4 -> 
        { :error, "The length is not 4" }
      guess |> String.graphemes |> Enum.any?(&(&1 < "0" || &1 > "9")) -> 
        { :error, "All chars need to be digits" }
      st.guesses |> List.flatten |> Enum.member?(guess) -> 
        { :error, "Repeated guess" }
      guess |> String.graphemes |> Enum.uniq |> length != 4 ->
        { :error, "All chars in the guess should be unique" }
      true -> :ok
    end
  end


  # Get the current view in the following format:
  # %{ state: "waiting", players: ready_map, scoreboard }
  # %{ state: "ongoing", guesses: guess_table, scoreboard }
  # %{ state: "game_over", players: results_map, scoreboard }
  #
  # Where 
  #  - a ready_map is a map from players to ready? bools
  #  - a guess_table is a list of maps of players to that rounds score
  #  - a results map is a map from players to win? bools
  def view(st) do
    case st.state do
      :ongoing -> 
        guesses = Enum.map(st.guesses, 
          fn y -> 
            Enum.map(y, &(view_1(&1, st.secret))) 
          end)
        guesses = Enum.map(guesses, &(st.players |> Enum.zip(&1) |> Map.new))
        %{ 
          state: :ongoing, 
          guesses: guesses,
          scoreboard: st.scoreboard,
        }
      _ -> st
    end
  end

  # Converts a guess and a secret to a view in the following form: 
  # { bulls, cows, guess }
  defp view_1(guess, secret) do
    if guess === "" do
      %{ guess: "", bulls: 0, cows: 0 }
    else
      split_secret = String.graphemes(secret)

      bulls = guess
              |> String.graphemes
              |> Enum.zip(split_secret)
              |> Enum.filter(fn({a, b}) -> a == b end)
              |> length

      cows = guess 
             |> String.graphemes 
             |> Enum.filter(&(Enum.member?(split_secret, &1)))
             |> length
             |> Kernel.-(bulls)

      %{
        guess: guess,
        bulls: bulls, 
        cows: cows 
      }
    end
  end 


  # Generate a random 4 digit secret where all digits are different
  defp random_secret() do
    s = MapSet.new();
    s = add_num(s)
    s |> Enum.shuffle |> Enum.join("")
  end

  # Adds upto 4 numbers to a set
  defp add_num(s) do
    if MapSet.size(s) == 4 do
      s
    else
      add_num(MapSet.put(s, Enum.random(0..9)))
    end
  end
end
