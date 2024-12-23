defmodule Qwhiplash.Core.Player do
  @moduledoc """
  Represents a player in the game.
  """

  @type id :: String.t()
  @type t :: %__MODULE__{
          score: integer(),
          online: boolean(),
          name: String.t()
        }

  defstruct [:score, :online, :name]

  @spec new(String.t()) :: %__MODULE__{}
  def new(name) do
    %__MODULE__{score: 0, online: true, name: name}
  end

  @spec update_score(t(), integer()) :: t()
  def update_score(player, score) do
    %{player | score: player.score + score}
  end

  @spec update_online(t(), boolean()) :: t()
  def update_online(player, online) do
    %{player | online: online}
  end
end
