defmodule Qwhiplash.Core.Round do
  @moduledoc """
  Quiplash has rounds where players submit their answers to prompts.
  There should be 3 rounds in a game.
  Each round players are randomly paired up and given a prompt.
  Each player submits an answer to the prompt.
  After all the answers are submitted, the players vote on the best answer.

  ## Usage
  users = ["user1", "user2", "user3", "user4"]

  round = Round.new(0, users, [], ["prompt1", "prompt2", "prompt3", "prompt4"])

  round = Round.add_answer(round, "user1", "answer1")

  round = Round.vote(round, "user2", "user1")
  """

  require Logger
  alias Qwhiplash.Core.Player

  @type id :: String.t()

  @type duels :: %{
          {id(), id()} => %{
            prompt: String.t(),
            answers: %{
              id() => %{
                answer: String.t(),
                votes: list(Player.id())
              }
            }
          }
        }

  @type t :: %__MODULE__{
          round_index: integer(),
          duels: duels()
        }

  defstruct [:round_index, :duels]

  @spec new(
          integer(),
          list(Player.t()),
          list({Player.id(), Player.id()}),
          list(String.t())
        ) :: t()
  def new(index, players, played_duels, prompts) do
    duels = generate_duel_pairings(players, played_duels) |> generate_duels(prompts)
    %__MODULE__{round_index: index, duels: duels}
  end

  @doc """
  Adds an answer to a duel of a given player.
  If the player is not in a duel, it will raise an error.
  """
  @spec add_answer!(t(), Player.id(), String.t()) :: t()
  def add_answer!(round, player, answer) do
    case find_player_duel(round, player) do
      nil -> raise "Player not in duel"
      {duel, _} -> add_answer!(round, duel, player, answer)
    end
  end

  @spec add_answer!(t(), {Player.id(), Player.id()}, Player.id(), String.t()) :: t()
  def add_answer!(round, duel, player, answer) do
    case Map.get(round.duels, duel) do
      %{} = duel_data ->
        updated_duel =
          duel_data
          |> Map.update!(:answers, &Map.put(&1, player, %{answer: answer, votes: []}))

        %{round | duels: Map.put(round.duels, duel, updated_duel)}

      nil ->
        raise "Duel not found"
    end
  end

  @spec vote!(t(), Player.id(), Player.id()) :: t()
  def vote!(round, voter, player) do
    case find_player_duel(round, player) do
      nil -> raise "Player not in duel"
      {duel, _} -> vote!(round, voter, duel, player)
    end
  end

  @spec vote!(t(), Player.id(), {Player.id(), Player.id()}, Player.id()) :: t()
  def vote!(round, voter, duel, player) do
    answers = Map.get(round.duels, duel).answers

    case Map.get(answers, player) do
      nil ->
        raise "Player has no answer"

      %{votes: _} ->
        updated_answers =
          Map.update!(answers, player, fn %{votes: current_votes} = answer ->
            %{answer | votes: Enum.uniq([voter | current_votes])}
          end)

        updated_duel = Map.put(round.duels[duel], :answers, updated_answers)
        %{round | duels: Map.put(round.duels, duel, updated_duel)}
    end
  end

  @spec get_scores(t()) :: %{Player.id() => integer()}
  def get_scores(%{duels: duels}) do
    duels
    |> Enum.reduce(%{}, fn {_, %{answers: answers}}, acc ->
      Enum.reduce(answers, acc, fn {player, %{votes: votes}}, acc ->
        Map.put(acc, player, length(votes))
      end)
    end)
  end

  @spec get_player_answer(t(), Player.id()) :: String.t() | nil
  def get_player_answer(round, player) do
    case find_player_duel(round, player) do
      nil -> nil
      {duel, _} -> Map.get(Map.get(round.duels, duel).answers, player)
    end
  end

  defp find_player_duel(round, player) do
    Enum.find(round.duels, fn {key, _} ->
      elem(key, 0) == player or elem(key, 1) == player
    end)
  end

  defp generate_duels(pairings, prompts) do
    pairings
    |> Enum.reduce(%{}, fn pairing, acc ->
      Map.put(acc, pairing, random_prompt(prompts) |> create_duel())
    end)
  end

  defp create_duel(prompt) do
    %{
      prompt: prompt,
      answers: %{}
    }
  end

  defp random_prompt(prompts) do
    Enum.random(prompts)
  end

  defp generate_duel_pairings(players, played_duels) do
    all_pairs =
      players
      |> Enum.with_index()
      |> Enum.flat_map(fn {p1, _} ->
        Enum.filter(players, fn p2 -> p1 < p2 end)
        |> Enum.map(fn p2 -> {p1, p2} end)
      end)

    new_duels = Enum.reject(all_pairs, &Enum.member?(played_duels, &1))

    selected_duels = Enum.take(new_duels, div(length(players), 2))

    selected_duels
  end
end
