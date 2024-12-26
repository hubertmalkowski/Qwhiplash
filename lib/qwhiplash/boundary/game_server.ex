defmodule Qwhiplash.Boundary.GameServer do
  alias Qwhiplash.Core.Player
  alias Qwhiplash.Core.Game
  use GenServer

  @spec start_link({pid(), list(String.t())}) :: {:ok, pid()} | {:error, term()}
  def start_link({host_pid, prompts}) do
    GenServer.start_link(__MODULE__, {host_pid, prompts})
  end

  @spec start_game(pid()) :: :ok
  def start_game(pid) do
    GenServer.call(pid, {:start})
  end

  @spec exit_game(pid()) :: :ok
  def exit_game(pid) do
    GenServer.call(pid, {:exit})
  end

  @spec add_player(pid(), String.t()) ::
          {:ok, String.t()} | {:error, :invalid_state} | {:error, :player_exists}
  def add_player(pid, name) do
    GenServer.call(pid, {:add_player, name})
  end

  def answer(pid, player_id, answer) do
    GenServer.call(pid, {:answer, player_id, answer})
  end

  def finish_answer_phase(pid) do
    GenServer.call(pid, {:finish_answer_phase})
  end

  def vote(pid, player_id, voter_id) do
  end

  def finish_voting_phase(pid) do
  end

  def finish_results_phase(pid) do
  end

  def finish_game(pid) do
  end

  # GenServer callbacks

  @impl true
  def init({host_pid, init}) do
    game = Game.new(host_pid, init)
    {:ok, game}
  end

  @impl true
  def handle_call({:start}, _from, %Game{} = game) do
    game = Game.start_game(game)
    {:reply, :ok, game}
  end

  def handle_call({:exit}, _from, %Game{} = game) do
    game = Game.exit_game(game)
    {:reply, :ok, game}
  end

  def handle_call({:add_player, name}, _from, state) do
    player = Player.new(name)

    case Game.add_player(state, player) do
      {:ok, game, uuid} -> {:reply, {:ok, uuid}, game}
      {:error, error_message} -> {:reply, {:error, error_message}, state}
    end
  end

  def handle_call({:answer, player_id, answer}, _from, state) do
    case Game.answer(state, player_id, answer) do
      {:ok, game} -> {:reply, :ok, game}
      {:error, error_message} -> {:reply, {:error, error_message}, state}
    end
  end

  def handle_call({:finish_answer_phase}, _from, state) do
    game = Game.finish_answer_phase(state)
    {:reply, :ok, game}
  end
end
