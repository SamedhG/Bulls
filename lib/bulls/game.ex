defmodule Bulls.Game do

  # Create a new game instance
  def new() do
    %{
      secret: random_secret(),
      guesses: []
    }
  end


  # Checks for the following things:
  # - Repeats in the guess
  # - All digits
  # - Repeats with other guesses
  # - The length should be 4
  # returns a new state if the guess was valid else returns an error object
  def guess(st, guess) do 
    cond do
      Enum.member?(st.guesses, st.secret) -> 
        { :error, "You Win" }
      length(st.guesses) >= 8 -> 
        { :error, "You Lose" }
      String.length(guess) != 4 -> 
        { :error, "The length is not 4" }
      guess |> String.graphemes |> Enum.any?(&(&1 < "0" || &1 > "9")) -> 
        { :error, "All chars need to be digits" }
      Enum.member?(st.guesses, guess) -> 
        { :error, "Repeated guess" }
      guess |> String.graphemes |> Enum.uniq |> length != 4 ->
        { :error, "All chars in the guess should be unique" }
      true -> {:ok, %{ st | guesses: [ guess | st.guesses ] } }
    end
  end


  # Get the current view in the following format:
  # If the game is over then the returned object is :
  # { game_over: true, message: "reason" }
  # If the game is still going then the returned object is 
  # {game_over: false, guesses: [table of guess and scores]}
  def view(st) do
    cond do
      Enum.member?(st.guesses, st.secret) -> 
        %{ game_over: true, message: "You Win" }
      length(st.guesses) >= 8 -> 
        %{ game_over: true, message: "You Lose"}
      true ->
        %{ 
          game_over: false, 
          guesses: st.guesses |> Enum.map(&(view_1(&1, st.secret))) 
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
