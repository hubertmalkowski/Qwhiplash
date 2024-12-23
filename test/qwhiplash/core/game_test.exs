defmodule Qwhiplash.Core.GameTest do
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

    test "add_player/2 returns error if game is not in pending state" do
      game = Game.new([])
      player = Player.new("player1")

      game = %{game | status: :answering}
      {:error, :invalid_state} = Game.add_player(game, player)
    end

    test "start_game/1 changes the status to playing and creates a round" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)

      assert game.status == :answering
      assert map_size(game.rounds) == 1
      assert game.current_round == 0

      current_round = Game.get_current_round(game)
      assert map_size(current_round.duels) == 4
    end

    test "answer/3 adds answer to the current round" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)
      player_id = Map.keys(game.players) |> hd()

      {:ok, game} = Game.answer(game, player_id, "answer1")

      current_round = Game.get_current_round(game)

      assert current_round |> Round.get_player_answer(player_id) == "answer1"
    end

    test "answer/3 returns error if game is not in answering state" do
      game = QwiplashFixtures.game_fixture()

      {:error, :invalid_state} = Game.answer(game, "player1", "answer1")

      assert game.status == :pending
    end

    test "answer/3 returns error if player is not in the game or has no duel" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)

      {:error, :not_in_duel} =
        Game.answer(game, "random_player_that_for_sure_exist", "answer1")
    end

    test "answer/3 changes the game status to voting if all players have answered" do
      game = QwiplashFixtures.game_fixture(2)

      game = Game.start_game(game)
      player_id = Map.keys(game.players) |> hd()

      {:ok, game} = Game.answer(game, player_id, "answer1")

      assert game.status == :answering

      player2_id = Map.keys(game.players) |> tl() |> hd()

      {:ok, game} = Game.answer(game, player2_id, "answer2")

      assert game.status == :voting
    end

    test "finish_answer_phase/1 changes the game status to voting" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)
      game = Game.finish_answer_phase(game)

      assert game.status == :voting
    end

    test "vote/3 adds a vote to the current round" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)
      player_id = Map.keys(game.players) |> hd()

      {:ok, game} = Game.answer(game, player_id, "answer1")

      player2_id = Map.keys(game.players) |> tl() |> hd()

      game = %{game | status: :voting}
      {:ok, game} = Game.vote(game, player2_id, player_id)

      current_round = Game.get_current_round(game)
      assert current_round |> Round.get_player_votes(player_id) == [player2_id]
    end

    test "vote/3 returns error if game is not in voting state" do
      game = QwiplashFixtures.game_fixture()

      {:error, :invalid_state} = Game.vote(game, "player1", "player2")

      assert game.status == :pending
    end

    test "vote/3 returns error if voter is not in the game" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)

      game = %{game | status: :voting}
      {:error, :invalid_voter} = Game.vote(game, "random_player", "player1")
    end

    test "vote/3 returns error if player is not in the game or has no duel" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)

      voter_id = Map.keys(game.players) |> hd()

      game = %{game | status: :voting}
      {:error, :not_in_duel} = Game.vote(game, voter_id, "player50")
    end

    test "finish_voting_phase/1 changes the game status to results if there is next round" do
      game = QwiplashFixtures.game_fixture()

      game =
        Game.start_game(game)
        |> Game.finish_answer_phase()

      game = Game.finish_voting_phase(game)

      assert game.status == :results
    end

    test "finish_voting_phase/1 changes the game status to finished if there is no next round" do
      game = QwiplashFixtures.game_fixture()

      game =
        Game.start_game(game)
        |> Map.put(:round_limit, 1)
        |> Game.finish_answer_phase()
        |> Game.finish_voting_phase()

      assert game.status == :finished
    end

    test "get_current_round/1 returns the current round" do
      game = QwiplashFixtures.game_fixture()

      game = Game.start_game(game)

      current_round = Game.get_current_round(game)

      assert current_round == Map.get(game.rounds, game.current_round)
    end

    test "finish_results_phase/1 changes the game status to answering and increments the current round" do
      game = QwiplashFixtures.game_fixture()

      game =
        Game.start_game(game)
        |> Game.finish_answer_phase()
        |> Game.finish_voting_phase()

      game = Game.finish_results_phase(game)

      assert game.status == :answering
      assert game.current_round == 1
    end

    test "game_finished?/1 returns true if the game is finished" do
      game = QwiplashFixtures.game_fixture()

      game =
        Game.start_game(game)
        |> Map.put(:round_limit, 1)
        |> Game.finish_answer_phase()
        |> Game.finish_voting_phase()

      assert Game.game_finished?(game)
    end
  end
end
