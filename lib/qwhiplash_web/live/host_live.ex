defmodule QwhiplashWeb.HostLive do
  require Logger
  alias Qwhiplash.Boundary.GameServer
  alias Qwhiplash.GameDynamicSupervisor
  use QwhiplashWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full">
      <header class="flex justify-between items-center">
        <div class="text-primary text-8xl font-extrabold">{@game_code}</div>
        <button phx-click="start_game" class="btn btn-primary btn-lg shadow-md">Start game</button>
      </header>

      <div class="flex flex-col gap-4 pt-4">
        <%= for {player_id, player} <- @game.players do %>
          <div class="card card-body shadow-md bg-base-200 text-2xl font-bold">{player.name}</div>
        <% end %>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, session, socket) do
    case GameDynamicSupervisor.find_game_by_host_id(session["session_id"]) do
      {:ok, pid, game} ->
        GameServer.subscribe(pid)
        {:ok, assign(socket, game_pid: pid) |> assign_game_code(game) |> assign(game: game)}

      nil ->
        {:ok, push_navigate(socket, to: "/")}
    end
  end

  @impl true
  def handle_info({:game_state_update, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  def handle_info(msg, socket) do
    Logger.debug("Unhandled message: #{inspect(msg)}")

    {:noreply, socket}
  end

  defp assign_game_code(socket, game) do
    assign(socket, game_code: game.code)
  end
end
