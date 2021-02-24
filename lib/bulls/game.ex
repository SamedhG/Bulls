defmodule Bulls.Game do

  # Create a new game instance
  # A Guess contains a n-tuple of n players
  # Players is a tuple of player names
  def new(players) do
    %{
      secret: random_secret(),
      guesses: [],
      players: players,
    }
  end

  # Assumes that all guesses have been validated previously
  def guess(st, guesses) do
    if length(st.players) == length(guesses) do
      { :ok, %{ st | guesses: [ guesses | st.guesses ] } }
    else
      { :error, "Invalid number of guesses" }
    end
  end

  # Checks for the following things:
  # - Repeats in the guess
  # - All digits
  # - Repeats with other guesses
  # - The length should be 4
  # returns a new state if the guess was valid else returns an error object
  def validate(st, guess) do 
    cond do
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
  # If the game is over then the returned object is :
  # { game_over: true, results: %{"p1" => "win", "p2" => "lose" ...} }
  # If the game is still going then the returned object is 
  # {game_over: false, guesses: [table of guess and scores]}
  def view(st) do
    cond do
      Enum.member?(hd(st.guesses), st.secret) ->
        results = Map.new(Enum.zip(st.players, Enum.map(hd(st.guesses), &(if &1 === st.secret do "win" else "lose" end))))
        %{ game_over: true, results: results}
      true ->
        guesses = Enum.map(st.guesses, 
          fn y -> 
            Enum.map(y, &(view_1(&1, st.secret))) 
        end)
        guesses = Enum.map(guesses, &(st.players |> Enum.zip(&1) |> Map.new))
        %{ 
          game_over: false, 
          guesses: guesses 
        }
    end

  end

  # Converts a guess and a secret to a view in the following form: 
  # { bulls, cows, guess }
  defp view_1(guess, secret) do
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
