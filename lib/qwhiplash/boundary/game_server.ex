defmodule Qwhiplash.Boundary.GameServer do
  require Logger
  alias Phoenix.PubSub
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

  @spec add_player(pid(), String.t(), binary()) ::
          {:ok, String.t()}
          | {:error, :invalid_state}
          | {:error, :player_exists}
          | {:ok, :reconnected, String.t()}
  def add_player(pid, name, id) do
    GenServer.call(pid, {:add_player, name, id})
  end

  @spec subscribe(pid()) :: :ok
  def subscribe(pid) do
    {:ok, code} = get_game_code(pid)
    PubSub.subscribe(Qwhiplash.PubSub, pubsub_topic(code))
  end

  @spec unsubscribe(pid()) :: :ok
  def unsubscribe(pid) do
    {:ok, code} = get_game_code(pid)
    PubSub.unsubscribe(Qwhiplash.PubSub, pubsub_topic(code))
  end

  @spec answer(pid(), Player.id(), String.t()) :: :ok
  def answer(pid, player_id, answer) do
    GenServer.call(pid, {:answer, player_id, answer})
  end

  def finish_answer_phase(pid) do
    GenServer.call(pid, {:finish_answer_phase})
  end

  def get_host_id(pid) do
    GenServer.call(pid, {:get_host_id})
  end

  @spec get_game_code(pid()) :: {:ok, String.t()}
  def get_game_code(pid) do
    GenServer.call(pid, {:get_game_code})
  end

  def get_game_state(pid) do
    GenServer.call(pid, {:get_game_state})
  end

  def vote(pid, voter_id, player_id) do
    GenServer.call(pid, {:vote, voter_id, player_id})
  end

  # GenServer callbacks

  @impl true
  def init({host_pid, init}) do
    game = Game.new(host_pid, init)
    {:ok, game}
  end

  @impl true
  def handle_call({:start}, _from, %Game{} = game) do
    game = Game.start_game(game) |> schedule_state_expiry()
    send_game_state(game)
    {:reply, :ok, game}
  end

  def handle_call({:exit}, _from, %Game{} = game) do
    game = Game.exit_game(game)
    send_game_state(game)
    {:reply, :ok, game}
  end

  def handle_call({:add_player, name, id}, _from, state) do
    player = Player.new(name)

    case Game.add_player(state, player, id) do
      {:ok, game, uuid} ->
        send_game_state(game)
        {:reply, {:ok, uuid}, game}

      {:ok_reconnected, game, uuid} ->
        send_game_state(game)
        {:reply, {:ok, :reconnected, uuid}, game}

      {:error, error_message} ->
        {:reply, {:error, error_message}, state}
    end
  end

  def handle_call({:answer, player_id, answer}, _from, state) do
    case Game.answer(state, player_id, answer) do
      {:ok, game} ->
        game =
          if game.status != :answering do
            schedule_state_expiry(game)
          else
            game
          end

        send_game_state(game)
        {:reply, :ok, game}

      {:error, error_message} ->
        {:reply, {:error, error_message}, state}
    end
  end

  def handle_call({:vote, voter_id, player_id}, _from, state) do
    case Game.vote(state, voter_id, player_id) do
      {:ok, game} ->
        game =
          if state.status != game.status do
            schedule_state_expiry(game)
          else
            game
          end

        send_game_state(game)
        {:reply, :ok, game}

      {:error, error_message} ->
        {:reply, {:error, error_message}, state}
    end
  end

  def handle_call({:finish_answer_phase}, _from, state) do
    game = Game.finish_answer_phase(state)
    send_game_state(game)
    {:reply, :ok, game}
  end

  def handle_call({:get_host_id}, _from, state) do
    {:reply, {:ok, state.host_id}, state}
  end

  def handle_call({:get_game_code}, _from, state) do
    {:reply, {:ok, state.code}, state}
  end

  def handle_call({:get_game_state}, _from, state) do
    {:reply, {:ok, state}, state}
  end

  @impl true
  def handle_info({:timeout, :answering}, state) do
    {:ok, game} = Game.finish_answer_phase(state)
    game = schedule_state_expiry(game)
    send_game_state(game)
    {:noreply, game}
  end

  def handle_info({:timeout, {:voting, _}}, state) do
    game = Game.finish_voting_phase(state) |> schedule_state_expiry()
    send_game_state(game)
    {:noreply, game}
  end

  def handle_info({:timeout, :results}, state) do
    game = Game.finish_results_phase(state) |> schedule_state_expiry()
    send_game_state(game)
    {:noreply, game}
  end

  defp send_game_state(game) do
    Logger.debug("Sending game state update #{inspect(game)}")
    PubSub.broadcast(Qwhiplash.PubSub, pubsub_topic(game.code), {:game_state_update, game})
  end

  defp pubsub_topic(code), do: "game:#{code}"

  # schedules the game to expire after a certain amount of time
  # 120 seconds for answering, 60 seconds for voting, 10 seconds for results
  # It assigns timer_info to the game. The timer_info is {timer_ref, timer_end_DateTime}
  # After the timer expires, it sends a message to the game server to handle the timeout
  # The message is {:timeout, :answering} or {:timeout, :voting} or {:timeout, :results}
  defp schedule_state_expiry(game) do
    game =
      if Map.get(game, :timer_info) != nil do
        cancel_state_expiry(game)
      else
        game
      end

    schedule_time =
      case game.status do
        :answering -> 120
        {:voting, _} -> 60
        :results -> 10
        _ -> 0
      end

    if schedule_time > 0 do
      timer_end_time = DateTime.utc_now() |> DateTime.add(schedule_time, :second)
      timer_ref = Process.send_after(self(), {:timeout, game.status}, schedule_time * 1000)
      %{game | timer_info: {timer_ref, timer_end_time}}
    else
      game
    end
  end

  defp cancel_state_expiry(game) do
    with {timer_ref, _} <- game.timer_info do
      Process.cancel_timer(timer_ref)
      %{game | timer_info: nil}
    else
      _ -> game
    end
  end
end
