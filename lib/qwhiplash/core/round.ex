defmodule Qwhiplash.Core.Round do
  @moduledoc """
  Quiplash has rounds where players submit their answers to prompts.
  There should be 3 rounds in a game.
  Each round players are randomly paired up and given a prompt.
  Each player submits an answer to the prompt.
  After all the answers are submitted, the players vote on the best answer.
  """

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

  @spec add_answer(t(), Player.id(), String.t()) :: t()
  def add_answer(round, player, answer) do
    with {duel, _} <- find_player_duel(round, player) do
      add_answer(round, duel, player, answer)
    else
      nil -> round
    end
  end

  @spec add_answer(t(), {Player.id(), Player.id()}, Player.id(), String.t()) :: t()
  def add_answer(round, duel, player, answer) do
    new_answers =
      Map.get(round.duels, duel).answers
      |> Map.put(player, %{answer: answer, votes: []})

    new_duel = Map.put(Map.get(round.duels, duel), :answers, new_answers)

    %{round | duels: Map.put(round.duels, duel, new_duel)}
  end

  @spec vote(t(), Player.id(), Player.id()) :: t()
  def vote(round, voter, player) do
    case find_player_duel(round, voter) do
      nil -> round
      {duel, _} -> vote(round, voter, duel, player)
    end
  end

  @spec vote(t(), Player.id(), {Player.id(), Player.id()}, Player.id()) :: t()
  def vote(round, voter, duel, player) do
    answers = Map.get(round.duels, duel).answers

    case Map.get(answers, player) do
      nil ->
        round

      %{votes: votes} ->
        new_votes = Enum.uniq([voter | votes])
        new_answers = Map.put(answers, player, %{answers[player] | votes: new_votes})
        new_duel = Map.put(Map.get(round.duels, duel), :answers, new_answers)

        %{round | duels: Map.put(round.duels, duel, new_duel)}
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
