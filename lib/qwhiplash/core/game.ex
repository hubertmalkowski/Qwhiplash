defmodule Qwhiplash.Core.Game do
  @moduledoc """
  Represents a Qwhiplash game which is basically Quiplash copy.

  ## Usage

  game = Game.new(["prompt1", "prompt2", "prompt3", "prompt4"])
    |> Game.add_player(Player.new("player1"))
    |> Game.add_player(Player.new("player2"))
    |> Game.start_game()
    |> Game.answer( "player1", "answer1")
    |> Game.answer( "player2", "answer2")
    |> Game.vote("player1", "player2")
    |> Game.vote("player2", "player1") # will automatically advance the round if all players have voted
    |> Game.advance_round()

  """
  alias Qwhiplash.Core.Player
  alias Qwhiplash.Core.Round

  @type id :: String.t()
  @type game_status :: :pending | :playing | :finished | :exiting
  @type game_state :: :prompting | :voting | :results | :finished

  @type t :: %__MODULE__{
          id: id(),
          code: String.t(),
          players: %{
            id() => Player.t()
          },
          current_round: integer(),
          status: game_status(),
          rounds: list(Round.t()),
          prompt_pool: list(String.t()),
          round_limit: integer()
        }

  @enforce_keys [:id, :code, :players, :rounds, :prompt_pool, :current_round, :status]
  defstruct [:id, :code, :players, :rounds, :prompt_pool, :current_round, :status, :round_limit]

  @spec new(list()) :: %__MODULE__{}
  def new(prompt_pool) do
    %__MODULE__{
      id: generate_uuid(),
      code: generate_code(),
      players: %{},
      rounds: [],
      prompt_pool: prompt_pool,
      current_round: 0,
      status: :pending,
      round_limit: 3
    }
  end

  @spec start_game(t()) :: t()
  def start_game(game) do
    game
    |> Map.put(:status, :playing)
    |> create_round()
  end

  @spec finish_game(t()) :: t()
  def finish_game(game) do
    %{game | status: :finished}
  end

  @spec exit_game(t()) :: t()
  def exit_game(game) do
    %{game | status: :exiting}
  end

  @spec advance_round(t()) :: t()
  def advance_round(game) do
    game =
      add_scores_from_current_round(game)

    next_current_round = game.current_round + 1

    if next_current_round == game.round_limit do
      finish_game(game)
    else
      Map.put(game, :current_round, next_current_round)
      |> create_round()
    end
  end

  @spec add_player(t(), Player.t()) :: {t(), Player.id()}
  def add_player(game, player) do
    uuid = generate_uuid()
    {%{game | players: Map.put(game.players, uuid, player)}, uuid}
  end

  @spec answer(t(), Player.id(), String.t()) :: t()
  def answer(game, player_id, answer) do
    replace_round =
      game
      |> get_current_round()
      |> Round.add_answer(player_id, answer)

    new_rounds =
      Enum.map(game.rounds, fn round ->
        if round.round_index == game.current_round do
          replace_round
        else
          round
        end
      end)

    %{game | rounds: new_rounds}
  end

  def vote(game, voter_id, player_id) do
    replace_round =
      game
      |> get_current_round()
      |> Round.vote(voter_id, player_id)

    new_rounds =
      Enum.map(game.rounds, fn round ->
        if round.round_index == game.current_round do
          replace_round
        else
          round
        end
      end)

    %{game | rounds: new_rounds}
  end

  @spec game_finished?(t()) :: boolean()
  def game_finished?(game) do
    game.status == :finished
  end

  @spec get_current_round(t()) :: Round.t()
  def get_current_round(game) do
    Enum.find(game.rounds, fn round -> round.round_index == game.current_round end)
  end

  defp create_round(game) do
    round =
      Round.new(game.current_round, list_player_ids(game), list_all_duels(game), game.prompt_pool)

    %{game | rounds: [round | game.rounds]}
  end

  defp add_scores_from_current_round(game) do
    scores =
      get_current_round(game)
      |> Round.get_scores()

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
    Enum.flat_map(game.rounds, &Map.keys(&1.duels))
  end

  defp list_player_ids(game) do
    Map.keys(game.players)
  end

  defp generate_uuid do
    UUID.uuid4()
  end
end
