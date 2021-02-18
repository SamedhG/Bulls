defmodule Bulls.BullsTest do
  use ExUnit.Case
  import Bulls.Game

  test "test guessing" do
    game = new()
    game = %{ game | secret: "1234" }
    {:ok, game} = guess(game, "4321")
    # too short
    assert {:error, _ } = guess(game, "123")
    # too long
    assert {:error, _ } = guess(game, "12345")
    # repeated digit
    assert {:error, _ } = guess(game, "1231")
    # repeated guess
    assert {:error, _ } = guess(game, "4321")
    # non-digit char
    assert {:error, _ } = guess(game, "123a")
  end

  test "test viewing game" do
    game = new()
    game = %{ game | secret: "1234" }
    {:ok, game} = guess(game, "4231")
    {:ok, game} = guess(game, "1235")
    %{ game_over: false, guesses: [v0, v1]} = view(game)

    assert v0.guess == "1235"
    assert v0.bulls == 3
    assert v0.cows == 0
    assert v1.guess == "4231"
    assert v1.bulls == 2
    assert v1.cows == 2
  end

  test "test winning game" do
    game = new()
    game = %{ game | secret: "1234" }
    {:ok, game} = guess(game, "4231")
    {:ok, game} = guess(game, "1234")
    assert %{game_over: true, message: "You Win"} = view(game)
  end

  test "test losing game" do
    game = new()
    game = %{ game | secret: "1234" }
    {:ok, game} = guess(game, "4231")
    {:ok, game} = guess(game, "1235")
    {:ok, game} = guess(game, "1236")
    {:ok, game} = guess(game, "1237")
    {:ok, game} = guess(game, "1238")
    {:ok, game} = guess(game, "1239")
    {:ok, game} = guess(game, "1249")
    {:ok, game} = guess(game, "1259")
    assert %{game_over: true, message: "You Lose"} = view(game)
  end

end
