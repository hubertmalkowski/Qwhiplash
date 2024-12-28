defmodule Qwhiplash.Core.Game do
  @moduledoc """
  Represents a Qwhiplash game which is basically Quiplash copy.

  Quiplash has following game states: 
  - pending: The game has been created but not started yet. During this state, players can join the game.
  - answering: Game has started and players are submitting their answers to prompts. This state happens each round.
  - voting: Players are voting on the best answer. This state happens each round.
  - results: The results after the round are being shown.
  - finished: The game has finished. The final scores are shown.
  - exiting: The game is being exited. After this state, the game is deleted.


           pending                    
              │                       
              │                       
              ▼                       
          answering ◄─────────────┐   
              │                   │   
              │                   │   
              ▼                   │   
            voting                │   
              │                   │   
              │                   │   
              ▼                   │   
    ┌────────────────────┐        │   
    │Round limit reached?│        │   
    └─────────┬─────────┬┘        │   
              │         │         │   
             nope      yep        │   
              │         │         │   
              ▼         │         │   
           finished     └─────►results
              │                       
              │                       
              ▼                       
           exiting
  """
  alias Qwhiplash.Core.Player
  alias Qwhiplash.Core.Round

  @type id :: String.t()
  @type game_status ::
          :pending | :answering | {:voting, MapSet.t()} | :results | :finished | :exiting

  @type t :: %__MODULE__{
          id: id(),
          code: String.t(),
          players: %{
            id() => Player.t()
          },
          host_id: binary(),
          current_round: integer(),
          status: game_status(),
          rounds: %{integer() => Round.t()},
          prompt_pool: list(String.t()),
          round_limit: integer()
        }

  @enforce_keys [:id, :code, :players, :rounds, :prompt_pool, :current_round, :status, :host_id]
  defstruct [
    :id,
    :code,
    :players,
    :rounds,
    :prompt_pool,
    :current_round,
    :status,
    :round_limit,
    :host_id
  ]

  @spec new(binary(), list()) :: %__MODULE__{}
  def new(host_id, prompt_pool) do
    %__MODULE__{
      id: generate_uuid(),
      code: generate_code(),
      players: %{},
      rounds: %{},
      prompt_pool: prompt_pool,
      host_id: host_id,
      current_round: 0,
      status: :pending,
      round_limit: 3
    }
  end

  @spec start_game(t()) :: t()
  def start_game(game) do
    game
    |> leap_to_next_state()
    |> create_round()
  end

  @spec exit_game(t()) :: t()
  def exit_game(game) do
    %{game | status: :exiting}
  end

  @doc """
  Adds a player to the game.
  If the player is already in the game it will return :ok_reconnected no matter what state of the game it is.
  If the player already exists it will return :player_exists error.
  If the game is not in the pending state it will return :invalid_state error.
  """
  @spec add_player(t(), Player.t(), binary()) ::
          {:ok, t(), Player.id()}
          | {:error, :player_exists}
          | {:error, :invalid_state}
          | {:ok_reconnected, t(), Player.id()}
          | {:error, :different_name}
  def add_player(game, player, session_id) do
    name_taken? = player_with_name_exists?(game, player.name)
    player_already_in_game? = player_with_id_exists?(game, session_id)

    cond do
      player_already_in_game? and name_taken? ->
        {:ok_reconnected, game, session_id}

      name_taken? ->
        {:error, :player_exists}

      game.status != :pending ->
        {:error, :invalid_state}

      true ->
        {:ok, %{game | players: Map.put(game.players, session_id, player)}, session_id}
    end
  end

  @doc """
  Adds an answer to the current round.
  If the player is not in a duel or the player does not exist it will return :not_in_duel error.
  If the game is not in the answering state it will return :invalid_state error.

  If all players have answered, it will finish the answer phase and leap to the next state (voting).
  """
  @spec answer(t(), Player.id(), String.t()) ::
          {:ok, t()} | {:error, :not_in_duel} | {:error, :invalid_state}
  def answer(%{status: :answering} = game, player_id, answer) do
    try do
      updated_round =
        game
        |> get_current_round()
        |> Round.add_answer!(player_id, answer)

      game =
        case Round.all_answered?(updated_round) do
          true ->
            {:ok, game} = finish_answer_phase(game)
            game

          false ->
            game
        end
        |> update_current_round(updated_round)

      {:ok, game}
    rescue
      _ -> {:error, :not_in_duel}
    end
  end

  def answer(_, _, _), do: {:error, :invalid_state}

  @doc """
  Finishes the answer phase and leaps to the next state (voting).
  """
  @spec finish_answer_phase(t()) :: {:ok, t()} | {:error, :invalid_state}
  def finish_answer_phase(%__MODULE__{status: :answering} = game) do
    {:ok,
     game
     |> leap_to_next_state()}
  end

  def finish_answer_phase(_), do: {:error, :invalid_state}

  @doc """
  Adds an answer to the current round.
  If the player is not in a duel or the player does not exist it will return :not_in_duel error.
  If the game is not in the answering state it will return :invalid_state error.
  If the voter is not a player in the game it will return :invalid_voter error.

  If all players have voted, it will leap to the next state (results).
  """
  @spec vote(t(), Player.id(), Player.id()) ::
          {:ok, t()}
          | {:error, :not_in_duel}
          | {:error, :invalid_state}
          | {:error, :invalid_voter}
  def vote(%{status: {:voting, duel}} = game, voter_id, player_id) do
    if player_is_in_game?(game, voter_id) do
      game
      |> get_current_round()
      |> vote_in_round(voter_id, player_id, duel)
      |> case do
        {:error, _reason} = error ->
          error

        round ->
          game =
            Round.get_voters(round, player_id)
            |> length()
            |> case do
              num_of_voters when num_of_voters == length(game.players) - 2 ->
                update_current_round(game, round)
                |> finish_voting_phase()

              _ ->
                update_current_round(game, round)
            end

          {:ok, game}
      end
    else
      {:error, :invalid_voter}
    end
  end

  def vote(_, _, _), do: {:error, :invalid_state}

  @spec finish_voting_phase(t()) :: t()
  def finish_voting_phase(%__MODULE__{status: {:voting, _}} = game) do
    game
    |> add_scores_from_current_round()
    |> leap_to_next_state()
  end

  @spec finish_results_phase(t()) :: t()
  def finish_results_phase(%__MODULE__{status: :results} = game) do
    game
    |> leap_to_next_state()
    |> next_round()
  end

  @spec game_finished?(t()) :: boolean()
  def game_finished?(game) do
    game.status == :finished
  end

  @spec get_current_round(t()) :: Round.t()
  def get_current_round(game) do
    Map.get(game.rounds, game.current_round)
  end

  def get_voted_duel(%{status: {:voting, duel}} = game),
    do: game |> get_current_round() |> Map.get(:duels) |> Map.get(duel)

  defp update_current_round(game, round) do
    %{game | rounds: Map.put(game.rounds, game.current_round, round)}
  end

  defp vote_in_round(round, voter_id, player_id, duel) do
    try do
      Round.vote!(round, voter_id, duel, player_id)
    rescue
      _ -> {:error, :not_in_duel}
    end
  end

  defp next_round(game) do
    %{game | current_round: game.current_round + 1}
    |> create_round()
  end

  defp create_round(game) do
    round =
      Round.new(list_player_ids(game), list_all_duels(game), game.prompt_pool)

    %{game | rounds: Map.put(game.rounds, game.current_round, round)}
  end

  defp add_scores_from_current_round(game) do
    {:voting, duel} = game.status

    scores =
      get_current_round(game)
      |> Round.get_score_from_duel(duel)

    players =
      Enum.reduce(scores, game.players, fn {player_id, score}, acc ->
        Player.update_score(acc[player_id], score)
      end)

    %{game | players: players}
  end

  # Generates a 4 letter code that ussers will use to join the game.
  @spec generate_code() :: String.t()
  defp generate_code do
    1..4
    |> Enum.map(fn _ -> Enum.random(?A..?Z) end)
    |> List.to_string()
  end

  @spec list_all_duels(t()) :: list({Player.id(), Player.id()})
  defp list_all_duels(game) do
    Enum.flat_map(game.rounds, &Map.keys(elem(&1, 1).duels))
  end

  defp player_is_in_game?(game, player_id) do
    Map.has_key?(game.players, player_id)
  end

  defp list_player_ids(game) do
    Map.keys(game.players)
  end

  defp generate_uuid do
    UUID.uuid4()
  end

  defp leap_to_next_state(%__MODULE__{status: :pending} = game), do: %{game | status: :answering}

  defp leap_to_next_state(%__MODULE__{status: :answering} = game),
    do: %{
      game
      | status: {:voting, get_current_round(game).duels |> Map.keys() |> hd()}
    }

  defp leap_to_next_state(%__MODULE__{status: {:voting, duel}} = game) do
    current_round = get_current_round(game)
    duels = Map.keys(current_round.duels)
    current_duel_index = duels |> Enum.find_index(fn x -> MapSet.equal?(duel, x) end)

    case current_duel_index do
      index when index + 1 == length(duels) ->
        if game.current_round + 1 == game.round_limit do
          %{game | status: :finished}
        else
          %{game | status: :results}
        end

      index ->
        next_voting_duel = get_current_round(game).duels |> Map.keys() |> Enum.at(index + 1)
        %{game | status: {:voting, next_voting_duel}}
    end
  end

  defp leap_to_next_state(%__MODULE__{status: :results} = game), do: %{game | status: :answering}

  defp leap_to_next_state(%__MODULE__{status: :finished} = game), do: %{game | status: :exiting}

  defp player_with_name_exists?(game, name) do
    Enum.any?(game.players, fn {_, player} -> player.name == name end)
  end

  defp player_with_id_exists?(game, player_id) do
    Map.has_key?(game.players, player_id)
  end
end
