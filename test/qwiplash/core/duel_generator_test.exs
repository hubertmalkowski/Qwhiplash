defmodule Qwhiplash.Core.DuelGeneratorTest do
  use ExUnit.Case
  alias Qwhiplash.Core.DuelGenerator

  describe "Duel generator" do
    test "combinations/1 generates unique pairings" do
      players = ["player1", "player2", "player3", "player4"]

      pairings = DuelGenerator.combinations(players)

      assert length(pairings) == 6
      assert Enum.uniq(pairings) |> length() == 6

      players = ["player1", "player2", "player3"]

      pairings = DuelGenerator.combinations(players)

      assert length(pairings) == 3
      assert Enum.uniq(pairings) |> length() == 3
    end

    test "generate/2 generates list of pairings where each players is paired once" do
      players = ["player1", "player2", "player3", "player4"]

      pairings = DuelGenerator.generate(players, [])

      assert length(pairings) == 2
      assert Enum.uniq(pairings) |> length() == 2

      players = ["player1", "player2", "player3"]

      pairings = DuelGenerator.generate(players, [])
      assert length(pairings) == 1
    end

    test "generate/2 filters out previous pairings" do
      players = ["player1", "player2", "player3", "player4"]

      previous_pairings = [
        MapSet.new(["player1", "player2"]),
        MapSet.new(["player3", "player4"])
      ]

      pairings = DuelGenerator.generate(players, previous_pairings)

      assert length(pairings) == 2
      assert Enum.uniq(pairings) |> length() == 2

      assert Enum.count(pairings, fn pairing ->
               MapSet.subset?(pairing, MapSet.new(["player1", "player2"])) or
                 MapSet.subset?(pairing, MapSet.new(["player3", "player4"]))
             end) == 0
    end
  end
end
