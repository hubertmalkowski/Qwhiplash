defmodule Qwhiplash.GameDynamicSupervisor do
  alias Qwhiplash.Core.Game
  alias Qwhiplash.Boundary.GameServer
  use DynamicSupervisor

  @prompts ["prompt1", "prompt2", "prompt3", "prompt4"]

  def start_link(_opts) do
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_game(host_id) do
    case find_game_by_host_id(host_id) do
      {:ok, pid, _} -> DynamicSupervisor.terminate_child(__MODULE__, pid)
      nil -> nil
    end

    DynamicSupervisor.start_child(
      __MODULE__,
      %{
        id: Qwhiplash.Boundary.GameServer,
        start: {Qwhiplash.Boundary.GameServer, :start_link, [{host_id, @prompts}]}
      }
    )
  end

  @spec find_game_by_host_id(String.t()) :: {:ok, pid(), Game.t()} | nil
  def find_game_by_host_id(id) do
    case DynamicSupervisor.which_children(__MODULE__)
         |> Enum.find(&match_host_id(&1, id)) do
      {_, pid, _, _} ->
        {:ok, state} = GameServer.get_game_state(pid)
        {:ok, pid, state}

      nil ->
        nil
    end
  end

  @spec find_game_by_game_code(String.t()) :: {:ok, pid(), Game.t()} | nil
  def find_game_by_game_code(id) do
    case DynamicSupervisor.which_children(__MODULE__)
         |> Enum.find(&match_game_code(&1, id)) do
      {_, pid, _, _} ->
        {:ok, state} = GameServer.get_game_state(pid)
        {:ok, pid, state}

      nil ->
        nil
    end
  end

  @spec find_game_by_code_and_player(String.t(), binary()) ::
          {:ok, pid(), Game.t()} | {:error, :not_found}
  def find_game_by_code_and_player(code, player_id) do
    with {:ok, pid, game} <- find_game_by_game_code(code),
         true <- Map.has_key?(game.players, player_id) do
      {:ok, pid, game}
    else
      _ -> {:error, :not_found}
    end
  end

  @impl true
  def init(_) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  defp match_host_id({_, pid, _, _}, id) do
    case GameServer.get_host_id(pid) do
      {:ok, host_id} -> host_id == id
      _ -> false
    end
  end

  defp match_game_code({_, pid, _, _}, code) do
    case GameServer.get_game_code(pid) do
      {:ok, game_code} -> game_code == code
      _ -> false
    end
  end
end
