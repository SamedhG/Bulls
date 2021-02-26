defmodule Bulls.Game do

  # Create a new game instance:
  # A Game is one of: 
  #   - { started: false, players: {name: ready?} }
  #   - { started: true, 
  #       secret: "some secret", 
  #       guesses: [[]], 
  #       players: [],
  #       current_guesses: []
  #     }
  def new() do
    %{
      started: false,
      players: %{}
    }
  end

  def reset(st) do
    if st.started do 
      %{
        started: false,
        players: Enum.reduce(st.players, %{}, &(Map.put(&2, &1, false)))
      }
    else
      st
    end
  end
  ## Prestarting Functionality

  # Add a new player to the game (Upto 4)
  def add_player(st, name) do
    cond do
      st.started -> 
        { :error, "Game has already started" }
      st.players |> Map.keys |> length >= 4 ->
        { :error, "Max players of game reached" }
      Map.has_key?(st.players, name) ->
        { :error, "A player with this name is already in the game" }
      true -> { :ok, %{ st | players: Map.put(st.players, name, false) } }
    end
  end

  # Make a player ready, if all players (atleast 2) are ready game will start
  def ready(st, name) do
    cond do
      st.started -> 
        { :error, "Game has already started" }
      !Map.has_key?(st.players, name) ->
        { :error, "You need to join before getting ready" }
      true -> 
        players = Map.put(st.players, name, true)
        if length(Map.keys(players)) >= 2 && Enum.all?(Map.values(players)) do
          players = Map.keys(players)
          { :ok, %{ 
            started: true, 
            secret: random_secret(),
            guesses: [],
            current_guesses: Enum.map(players, fn _ -> "" end),
            players: players
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
      !st.started ->  { :error, "Game has not started yet" }
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
      !st.started -> { :error, "Game has not started yet" }
      true -> 
        empty = Enum.map(st.players, fn _ -> "" end)
        { :ok, %{ st | 
          guesses: [ st.current_guesses | st.guesses ],
          current_guesses: empty
        } }
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
  # %{ state: "waiting", players: ready_map }
  # %{ state: "ongoing", guesses: guess_table }
  # %{ state: "game_over", results: results_map }
  #
  # Where 
  #  - a ready_map is a map from players to ready? bools
  #  - a guess_table is a list of maps of players to that rounds score
  #  - a results map is a map from players to win? bools
  def view(st) do
    cond do
      !st.started -> 
        %{ state: "waiting", players: st.players }
      length(st.guesses) >= 1 && Enum.member?(hd(st.guesses), st.secret) ->
        results = Map.new(Enum.zip(st.players, Enum.map(hd(st.guesses), &(&1 === st.secret))))
        %{ state: "game_over", results: results }
      true ->
        guesses = Enum.map(st.guesses, 
          fn y -> 
            Enum.map(y, &(view_1(&1, st.secret))) 
          end)
        guesses = Enum.map(guesses, &(st.players |> Enum.zip(&1) |> Map.new))
        %{ 
          state: "ongoing", 
          guesses: guesses 
        }
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
