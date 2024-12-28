defmodule QwhiplashWeb.HostComponents do
  use Phoenix.Component

  attr :game_code, :string, required: true
  attr :players, :map, required: true

  def pending(assigns) do
    ~H"""
    <div class="h-full">
      <header class="flex justify-between items-center">
        <div class="text-primary text-8xl font-extrabold">{@game_code}</div>
        <button phx-click="start_game" class="btn btn-primary btn-lg shadow-md">Start game</button>
      </header>

      <div class="flex flex-col gap-4 pt-4">
        <%= for {_player_id, player} <- @players do %>
          <div class="card card-body shadow-md bg-base-200 text-2xl font-bold">{player.name}</div>
        <% end %>
      </div>
    </div>
    """
  end

  def answer(assigns) do
    ~H"""
    <div class="text-8xl font-bold text-primary">
      Answer questions on your devices
    </div>
    """
  end
end
