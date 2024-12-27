defmodule QwhiplashWeb.GameLive do
  alias Qwhiplash.Boundary.GameServer
  alias Qwhiplash.GameDynamicSupervisor
  use QwhiplashWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full">
      <header class="flex justify-between items-center">
        <div class="text-primary text-8xl font-extrabold">
          Hey <span class="text-secondary">{@game.players[@player_id].name}</span>
          Wait for the host to start the game
        </div>
      </header>
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
         |> assign(game: game)}

      {:error, :not_found} ->
        {:ok, push_navigate(socket, to: "/")}
    end
  end

  @impl true
  def handle_info({:game_state_update, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end
end
