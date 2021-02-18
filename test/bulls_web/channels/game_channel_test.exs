defmodule BullsWeb.GameChannelTest do
  use BullsWeb.ChannelCase

  setup do
    {:ok, _, socket} =
      BullsWeb.UserSocket
      |> socket()
      |> subscribe_and_join(BullsWeb.GameChannel, "game:1")
    %{socket: socket}
  end

  test "make a guess", %{socket: socket} do
    ref = push socket, "guess", "4321"
    assert_reply ref, :ok, %{game_over: false, guesses: [%{bulls: _, cows: _, guess: "4321"}]}
  end

  test "make erroneous guess", %{socket: socket} do
    ref = push socket, "guess", "4324"
    assert_reply ref, :error, %{message: _}
  end

  test "reset", %{socket: socket} do
    ref = push socket, "reset", ""
    assert_reply ref, :ok, _
  end
end
