defmodule Qwhiplash.Core.DuelGenerator do
  @doc """
  Creates unique pairings of players while avoiding previous combinations.

  Args:
    players: List of player identifiers
    previous_pairings: List of MapSets with previous pairings (optional)
    
  Returns:
    List of MapSets containing player pairings
  """

  @spec generate(list(String.t()), list(MapSet.t())) :: list(MapSet.t())
  def generate(players, previous_games) do
    combinations(players)
    |> filter_previous_combinations(previous_games)
    |> pick_unique_pairings([])
  end

  defp pick_unique_pairings([], acc), do: acc

  defp pick_unique_pairings([pairing | rest], acc) do
    Enum.any?(acc, &(!MapSet.disjoint?(pairing, &1)))
    |> case do
      true -> pick_unique_pairings(rest, acc)
      false -> pick_unique_pairings(rest, [pairing | acc])
    end
  end

  defp filter_previous_combinations(all_combinations, previous_combinations) do
    all_combinations |> Enum.reject(&Enum.member?(previous_combinations, &1))
  end

  def combinations(players) do
    combinations(players, [])
  end

  defp combinations([], acc), do: acc

  defp combinations([player | rest], acc) do
    acc = rest |> Enum.map(fn p -> MapSet.new([player, p]) end) |> Enum.concat(acc)
    combinations(rest, acc)
  end
end
