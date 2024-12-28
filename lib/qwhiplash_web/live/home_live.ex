defmodule QwhiplashWeb.HomeLive do
  require Logger
  alias Qwhiplash.Boundary.GameServer
  alias Qwhiplash.GameDynamicSupervisor
  use QwhiplashWeb, :live_view

  def render(assigns) do
    ~H"""
    <form class="container space-y-4" phx-submit="join_game">
      <h1 class="text-xl font-bold">Join game</h1>
      <div class="space-y-2">
        <label class="input input-bordered flex items-center gap-2">
          Game code<input
            name="game_code"
            type="text"
            class="grow border-none !outline-none !ring-0"
            placeholder="xxxx"
          />
        </label>

        <label class="input input-bordered flex items-center gap-2">
          Name<input name="name" type="text" class="grow border-none !outline-none !ring-0" />
        </label>
      </div>
      <div class="space-y-4">
        <button class="btn btn-primary w-full ">Join game</button>
        <button type="button" phx-click="start_game" class="btn w-full ">Become a host</button>
      </div>
    </form>
    """
  end

  def mount(_conn, session, socket) do
    {:ok, assign(socket, id: session["session_id"])}
  end

  def handle_event("start_game", _params, socket) do
    case GameDynamicSupervisor.start_game(socket.assigns.id) do
      {:ok, _child} ->
        {:noreply,
         put_flash(socket, :info, "Game created!")
         |> push_navigate(to: "/host")}

      {:error, error} ->
        {:noreply, put_flash(socket, :error, "Failed to start game! #{inspect(error)}")}
    end
  end

  def handle_event("join_game", %{"name" => ""}, socket) do
    {:noreply, put_flash(socket, :error, "Name is required!")}
  end

  def handle_event("join_game", %{"game_code" => game_code, "name" => name}, socket) do
    user_id = socket.assigns.id

    case GameDynamicSupervisor.find_game_by_game_code(game_code) do
      {:ok, pid, _} ->
        case GameServer.add_player(pid, name, user_id) do
          {:ok, :reconnected, _} ->
            {:noreply,
             put_flash(socket, :info, "Reconnected!") |> push_navigate(to: "/game/#{game_code}")}

          {:ok, _} ->
            {:noreply,
             put_flash(socket, :info, "Joined game!") |> push_navigate(to: "/game/#{game_code}")}

          {:error, :invalid_state} ->
            {:noreply, put_flash(socket, :error, "Invalid state!")}

          {:error, :player_exists} ->
            {:noreply, put_flash(socket, :error, "Player exists!")}
        end

      nil ->
        {:noreply, put_flash(socket, :error, "Game not found!")}
    end
  end
end
