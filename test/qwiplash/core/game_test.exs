defmodule Qwiplash.Core.GameTest do
  require Logger
  alias Qwhiplash.Core.Round
  alias Qwhiplash.Core.Player
  alias Qwhiplash.QwiplashFixtures
  alias Qwhiplash.Core.Game
  use ExUnit.Case

  describe "Game core" do
    test "new/1 creates a game with a prompt pool, 4 letter code, and pending status" do
      game = Game.new(["prompt1", "prompt2", "prompt3", "prompt4"])

      assert String.length(game.code) == 4
      assert game.status == :pending
      assert game.prompt_pool == ["prompt1", "prompt2", "prompt3", "prompt4"]
    end

    test "add_player/2 adds a player to the game and returns players id" do
      game = Game.new([])
      player = Player.new("player1")
      {game, uuid} = Game.add_player(game, player)

      assert uuid
      assert map_size(game.players) == 1
    end

    test "start_game/1 changes the status to playing and creates a round" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)

      assert game.status == :playing
      assert length(game.rounds) == 1
      assert game.current_round == 0

      current_round = Game.get_current_round(game)
      assert current_round.round_index == 0
      assert map_size(current_round.duels) == 2
    end
  end
end
