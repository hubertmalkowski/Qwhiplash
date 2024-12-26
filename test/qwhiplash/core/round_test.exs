defmodule Qwhiplash.Core.RoundTest do
  require Logger
  alias Qwhiplash.Core.Round
  use ExUnit.Case

  describe "Round Core" do
    test "new/3 creates a round with duels" do
      users = ["user1", "user2", "user3", "user4"]

      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])
      assert map_size(round.duels) == 2

      duels = Map.keys(round.duels)
      flat_list = Enum.flat_map(duels, &MapSet.to_list/1)

      assert length(flat_list) == Enum.uniq(flat_list) |> length()
    end

    test "new/3 doesn't create duels that already happened" do
      users = ["user1", "user2", "user3", "user4"]

      played_duels = [
        {"user1", "user2"},
        {"user3", "user4"}
      ]

      round = Round.new(users, played_duels, ["prompt1", "prompt2", "prompt3", "prompt4"])

      assert map_size(round.duels) == 2
      assert Map.keys(round.duels) |> Enum.any?(fn duel -> duel in played_duels end) == false
    end

    test "add_answer!/3 adds an answer to a duel" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")

      assert Kernel.map_size(round.duels) == 2

      assert Map.get(round.duels, MapSet.new(["user1", "user2"])).answers["user1"].answer ==
               "answer1"

      assert Map.get(round.duels, MapSet.new(["user1", "user2"])).answers["user2"].answer ==
               "answer2"
    end

    test "add_answer/3 raises if duel not found" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      assert_raise RuntimeError, fn ->
        Round.add_answer!(round, "user5", "answer1")
      end
    end

    test "vote/3 adds a vote to a duel" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")

      round = Round.vote!(round, "user3", "user1")
      round = Round.vote!(round, "user4", "user1")

      votes = Map.get(round.duels, MapSet.new(["user1", "user2"])).answers["user1"].votes

      assert Kernel.map_size(round.duels) == 2
      assert Enum.sort(votes) == ["user3", "user4"]
    end

    test "get_scores/1 returns the scores for the round" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")

      round = Round.vote!(round, "user3", "user1")
      round = Round.vote!(round, "user4", "user1")

      scores = Round.get_scores(round)

      assert Map.get(scores, "user1") == 2
    end

    test "get_player_answer/2 returns the answer for a player" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")

      assert Round.get_player_answer(round, "user1") == "answer1"
      assert Round.get_player_answer(round, "user2") == "answer2"
    end

    test "get_player_answer/2 returns nil if player has no answer" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      assert Round.get_player_answer(round, "user1") == nil
    end

    test "get_player_votes/2 returns the votes for a player" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")

      round = Round.vote!(round, "user3", "user1")
      round = Round.vote!(round, "user4", "user1")

      assert Round.get_player_votes(round, "user1") == ["user4", "user3"]
    end

    test "all_has_answered?/1 returns true if all players have answered" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")
      round = Round.add_answer!(round, "user3", "answer3")
      round = Round.add_answer!(round, "user4", "answer4")

      assert Round.all_answered?(round)
    end
  end
end
