defmodule Qwhiplash.QwiplashFixtures do
  alias Qwhiplash.Core.Player
  alias Qwhiplash.Core.Game
  alias Qwhiplash.Core.Round

  # Generates a list of random UUIDs.
  def user_list_fixture(number \\ 8) do
    Enum.map(1..number, fn _ -> UUID.uuid4() end)
  end

  def create_round_fixture(
        users \\ user_list_fixture(),
        played_duels \\ [],
        prompts \\ ["prompt1", "prompt2", "prompt3", "prompt4"]
      ) do
    Round.new(users, played_duels, prompts)
  end

  def create_player(num \\ nil) do
    Player.new(username(num))
  end

  def create_players(number \\ 4) do
    Enum.map(1..number, fn num -> create_player(num) end)
  end

  def game_fixture() do
    game_fixture(8)
  end

  def game_fixture(user_amount) do
    game = Game.new(self(), ["prompt1", "prompt2", "prompt3", "prompt4"])

    create_players(user_amount)
    |> Enum.reduce(game, fn player, acc ->
      {:ok, game, _} = Game.add_player(acc, player)
      game
    end)
  end

  defp username(nil), do: "user#{Enum.random(1..1000)}"
  defp username(num), do: "user#{num}"
end
