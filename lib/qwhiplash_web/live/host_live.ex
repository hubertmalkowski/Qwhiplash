defmodule QwhiplashWeb.HostLive do
  require Logger
  alias Qwhiplash.Boundary.GameServer
  alias Qwhiplash.Core.Game
  alias Qwhiplash.GameDynamicSupervisor
  use QwhiplashWeb, :live_view
  import QwhiplashWeb.HostComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full">
      <%= if @countdown do %>
        <div phx-hook="Countdown" id="countdown">{@countdown}</div>
      <% end %>
      <%= case @game.status do %>
        <% :pending -> %>
          <.pending game_code={@game_code} players={@game.players} />
        <% :answering -> %>
          <.answer />
        <% {:voting, _} -> %>
          <.voting duel={@duel} />
        <% :results -> %>
          <.results players={@player_scores} />
        <% :finished-> %>
          <.results players={@player_scores} />
        <% _ -> %>
          <div class="text-primary text-8xl font-extrabold">
            UNHANDLED GAME STATE
          </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    case GameDynamicSupervisor.find_game_by_host_id(session["session_id"]) do
      {:ok, pid, game} ->
        GameServer.subscribe(pid)

        {:ok,
         assign(socket, game_pid: pid)
         |> assign_game_code(game)
         |> assign(game: game)
         |> assign_state_related_values(game)
         |> assign_countdown(game)}

      nil ->
        {:ok, push_navigate(socket, to: "/")}
    end
  end

  @impl true
  def handle_event("start_game", _params, socket) do
    case GameServer.start_game(socket.assigns.game_pid) do
      :ok ->
        {:noreply, put_flash(socket, :info, "Game started!")}
    end
  end

  def terminate(reason, socket) do
    game_pid = socket.assigns.game_pid

    game = socket.assigns.game

    if game.status == :finished do
      DynamicSupervisor.terminate_child(GameDynamicSupervisor, game_pid)
    end

    {:ok, socket}
  end

  @impl true
  def handle_info({:game_state_update, game}, socket) do
    {:noreply,
     assign(socket, game: game) |> assign_state_related_values(game) |> assign_countdown(game)}
  end

  defp assign_game_code(socket, game) do
    assign(socket, game_code: game.code)
  end

  defp assign_state_related_values(socket, %Game{status: {:voting, _}} = game) do
    currently_voted_duel = Game.get_voted_duel(game)

    socket
    |> assign(:duel, currently_voted_duel)
  end

  defp assign_state_related_values(socket, %Game{status: :results} = game) do
    socket
    |> assign(:player_scores, players_to_list(game.players))
  end

  defp assign_state_related_values(socket, %Game{status: :finished} = game) do
    socket
    |> assign(:player_scores, players_to_list(game.players))
  end

  defp assign_state_related_values(socket, _game) do
    socket
  end

  defp assign_countdown(socket, game) do
    with {_, finish_date} <- game.timer_info do
      time_diff = DateTime.diff(finish_date, DateTime.utc_now(), :second)

      socket
      |> assign(:countdown, time_diff)
    else
      _ ->
        socket
        |> assign(:countdown, nil)
    end
  end

  defp players_to_list(players) do
    Enum.map(players, fn {_player_id, player} ->
      player
    end)
    |> Enum.sort_by(& &1.score, :desc)
    |> Enum.with_index(1)
  end
end
