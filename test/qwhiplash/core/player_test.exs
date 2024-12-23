defmodule Qwhiplash.Core.PlayerTest do
  alias Qwhiplash.Core.Player
  use ExUnit.Case

  test "new/1 creates a new player with a given name" do
    player = Player.new("name")

    assert player.name == "name"
    assert player.online == true
    assert player.score == 0
  end

  test "update_score/2 adds player score to previous score" do
    player = Player.new("name") |> Player.update_score(20)

    assert player.score == 20

    player = Player.update_score(player, 30)

    assert player.score == 50
  end

  test "update_online/2 updates player online status" do
    player = Player.new("name") |> Player.update_online(false)

    assert player.online == false

    player = Player.update_online(player, true)

    assert player.online == true
  end
end
