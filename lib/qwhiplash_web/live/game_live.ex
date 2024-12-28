defmodule QwhiplashWeb.GameLive do
  alias Qwhiplash.Core.Round
  alias Qwhiplash.Boundary.GameServer
  alias Qwhiplash.Core.Game
  alias Qwhiplash.GameDynamicSupervisor
  use QwhiplashWeb, :live_view
  import QwhiplashWeb.GameComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full w-full">
      <%= case @game.status do %>
        <% :pending -> %>
          <.pending player_name={@current_player.name} />
        <% :answering -> %>
          <.answering prompt={@prompt} answered={@answered} />
        <% _ -> %>
          <div class="text-primary text-8xl font-extrabold">
            UNHANDLED GAME STATE
          </div>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(%{"game_code" => game_code}, session, socket) do
    id = session["session_id"]

    case GameDynamicSupervisor.find_game_by_code_and_player(game_code, id) do
      {:ok, pid, game} ->
        GameServer.subscribe(pid)

        {:ok,
         assign(socket, player_id: id)
         |> assign(game_pid: pid)
         |> handle_game_state_update(game)}

      {:error, :not_found} ->
        {:ok, push_navigate(socket, to: "/")}
    end
  end

  @impl true
  def handle_event("answer", %{"answer" => answer}, socket) do
    :ok = GameServer.answer(socket.assigns.game_pid, socket.assigns.player_id, answer)
    {:noreply, socket |> assign(:answered, true)}
  end

  @impl true
  def handle_info({:game_state_update, game}, socket) do
    {:noreply, handle_game_state_update(socket, game)}
  end

  @impl true
  def terminate(_reason, socket) do
    game_pid = socket.assigns.game_pid
    GameServer.unsubscribe(game_pid)
  end

  defp handle_game_state_update(socket, game) do
    socket
    |> assign(:game, game)
    |> assign(:current_player, Map.get(game.players, socket.assigns.player_id))
    |> state_related_assigns(game)
  end

  defp state_related_assigns(socket, %Game{status: :answering} = game) do
    current_round = game |> Game.get_current_round()
    prompt = current_round |> Round.get_prompt(socket.assigns.player_id)
    player_answered? = Round.get_player_answer(current_round, socket.assigns.player_id) != nil

    assign(socket, :prompt, prompt)
    |> assign(:answered, player_answered?)
  end

  defp state_related_assigns(socket, _game), do: socket
end
