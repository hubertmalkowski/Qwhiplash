defmodule Qwhiplash.Core.Game do
  @moduledoc """
  Represents a Qwhiplash game which is basically Quiplash copy.

  Quiplash has following game states: 
  - pending: The game has been created but not started yet. During this state, players can join the game.
  - answering: Game has started and players are submitting their answers to prompts. This state happens each round.
  - voting: Players are voting on the best answer. This state happens each round.
  - results: The results after the round are being shown.
  - finished: The game has finished. The final scores are shown.
  - exiting: The game is being exited.

     pending                 
        │                    
        ▼                    
    answering◄───┐           
        │        │           
        ▼        │for 3 turns
      voting     │           
        │        │           
        ▼        │           
     results─────┘           
        │                    
        ▼                    
     finished                
        │                    
        ▼                    


  """
  alias Qwhiplash.Core.Player
  alias Qwhiplash.Core.Round

  @type id :: String.t()
  @type game_status :: :pending | :answering | :voting | :results | :finished | :exiting

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
    |> leap_to_next_state()
    |> create_round()
  end

  @spec exit_game(t()) :: t()
  def exit_game(game) do
    %{game | status: :exiting}
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

  defp leap_to_next_state(%__MODULE__{status: :pending} = game), do: %{game | status: :answering}
  defp leap_to_next_state(%__MODULE__{status: :answering} = game), do: %{game | status: :voting}
  defp leap_to_next_state(%__MODULE__{status: :voting} = game), do: %{game | status: :results}

  defp leap_to_next_state(%__MODULE__{status: :results} = game) do
    if game.current_round == game.round_limit do
      %{game | status: :finished}
    else
      %{game | status: :answering}
    end
  end

  defp leap_to_next_state(%__MODULE__{status: :finished} = game), do: %{game | status: :exiting}
end
