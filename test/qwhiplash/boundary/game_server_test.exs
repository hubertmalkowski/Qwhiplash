defmodule Qwhiplash.Boundary.GameServerTest do
  alias Qwhiplash.Boundary.GameServer
  alias Qwhiplash.Core.Game
  use ExUnit.Case

  @prompts ["prompt1", "prompt2", "prompt3", "prompt4"]

  describe "GameServer" do
    test "start_game/0 starts a game" do
      {:ok, pid} = GenServer.start(Qwhiplash.Boundary.GameServer, {self(), @prompts})
      assert :ok = GameServer.start_game(pid)
    end

    test "exit_game/0 exits a game" do
      {:ok, pid} = GenServer.start(Qwhiplash.Boundary.GameServer, {self(), []})
      assert :ok = GameServer.exit_game(pid)
    end

    test "add_player/2 adds a player to the game" do
      {:ok, pid} = GenServer.start(Qwhiplash.Boundary.GameServer, {self(), @prompts})
      assert {:ok, uuid} = GameServer.add_player(pid, "player1")
    end

    test "add_player/2 returns error if game is not in pending state" do
      {:ok, pid} = GenServer.start(Qwhiplash.Boundary.GameServer, {self(), []})
      GameServer.start_game(pid)

      assert {:error, :invalid_state} = GameServer.add_player(pid, "player1")
    end

    test "add_player/2 returns error if player with the same name is already in the game" do
      {:ok, pid} = GenServer.start(Qwhiplash.Boundary.GameServer, {self(), @prompts})
      GameServer.add_player(pid, "player1")

      assert {:error, :player_exists} = GameServer.add_player(pid, "player1")
    end
  end
end
