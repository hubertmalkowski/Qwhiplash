defmodule Qwhiplash.Core.Game do
  @moduledoc """
  Represents a Qwhiplash game which is basically Quiplash copy.
  """
  alias Qwhiplash.Core.Player
  alias Qwhiplash.Core.Round

  @type id :: String.t()
  @type game_status :: :pending | :playing | :finished | :exiting

  @type t :: %__MODULE__{
          id: id(),
          code: String.t(),
          players: %{
            id() => Player.t()
          },
          rounds: list(Round.t())
        }

  @enforce_keys [:id, :code, :players]
  defstruct [:id, :code, :players, :rounds]

  @spec new(map()) :: %__MODULE__{}
  def new(attrs) do
    %__MODULE__{id: attrs.id, code: attrs.code, players: %{}, rounds: []}
  end

  @doc """
  Generates a 4 letter code that ussers will use to join the game.
  """
  @spec generate_code() :: String.t()
  def generate_code do
    1..4
    |> Enum.map(fn _ -> Enum.random(?A..?Z) end)
    |> List.to_string()
  end

  def had_dueled?(player, id) do
    Enum.member?(player.dueled, id)
  end

  @spec list_all_duels(t()) :: list({Player.id(), Player.id()})
  def list_all_duels(game) do
    Enum.flat_map(game.rounds, &Map.keys(&1.duels))
  end
end
