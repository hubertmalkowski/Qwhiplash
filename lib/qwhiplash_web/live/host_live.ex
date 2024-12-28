defmodule QwhiplashWeb.HostLive do
  require Logger
  alias Qwhiplash.Boundary.GameServer
  alias Qwhiplash.GameDynamicSupervisor
  use QwhiplashWeb, :live_view
  import QwhiplashWeb.HostComponents

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full">
      <%= case @game.status do %>
        <% :pending -> %>
          <.pending game_code={@game_code} players={@game.players} />
        <% :answering -> %>
          <.answer />
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
        {:ok, assign(socket, game_pid: pid) |> assign_game_code(game) |> assign(game: game)}

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

  @impl true
  def handle_info({:game_state_update, game}, socket) do
    {:noreply, assign(socket, game: game)}
  end

  @impl true
  def terminate(_reason, socket) do
    game_pid = socket.assigns.game_pid
    GameServer.unsubscribe(game_pid)
  end

  defp assign_game_code(socket, game) do
    assign(socket, game_code: game.code)
  end
end
