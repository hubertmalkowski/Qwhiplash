defmodule Qwhiplash.Core.RoundTest do
  alias Qwhiplash.QwiplashFixtures
  alias Qwhiplash.Core.Round
  use ExUnit.Case

  describe "Round Core" do
    test "new/4 creates a round with duels" do
      users = QwiplashFixtures.user_list_fixture()

      round = Round.new(0, users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])
      assert round.round_index == 0
      assert map_size(round.duels) == 4
    end

    test "new/4 doesn't create duels that already happened" do
      users = ["user1", "user2", "user3", "user4"]

      played_duels = [
        {"user1", "user2"},
        {"user3", "user4"}
      ]

      round = Round.new(0, users, played_duels, ["prompt1", "prompt2", "prompt3", "prompt4"])

      assert map_size(round.duels) == 2
      assert Map.keys(round.duels) |> Enum.any?(fn duel -> duel in played_duels end) == false
    end

    test "add_answer!/3 adds an answer to a duel" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(0, users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")

      assert Kernel.map_size(round.duels) == 2
      assert Map.get(round.duels, {"user1", "user2"}).answers["user1"].answer == "answer1"
      assert Map.get(round.duels, {"user1", "user2"}).answers["user2"].answer == "answer2"
    end

    test "vote/3 adds a vote to a duel" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(0, users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")

      round = Round.vote!(round, "user3", "user1")
      round = Round.vote!(round, "user4", "user1")

      votes = Map.get(round.duels, {"user1", "user2"}).answers["user1"].votes

      assert Kernel.map_size(round.duels) == 2
      assert Enum.sort(votes) == ["user3", "user4"]
    end

    test "get_scores/1 returns the scores for the round" do
      users = ["user1", "user2", "user3", "user4"]
      round = Round.new(0, users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

      round = Round.add_answer!(round, "user1", "answer1")
      round = Round.add_answer!(round, "user2", "answer2")

      round = Round.vote!(round, "user3", "user1")
      round = Round.vote!(round, "user4", "user1")

      scores = Round.get_scores(round)

      assert Map.get(scores, "user1") == 2
    end
  end
end
