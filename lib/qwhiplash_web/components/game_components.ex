defmodule QwhiplashWeb.GameComponents do
  use Phoenix.Component

  attr :player_name, :string, required: true

  def pending(assigns) do
    ~H"""
    <div class="text-primary text-8xl font-extrabold">
      Hey <span class="text-secondary">{@player_name}</span> Wait for the host to start the game
    </div>
    """
  end

  attr :prompt, :string, required: true
  attr :answered, :boolean, default: false

  def answering(assigns) do
    ~H"""
    <%= cond do %>
      <% @answered -> %>
        <div class="text-primary text-8xl font-extrabold">
          Waiting for other players to answer
        </div>
      <% @prompt == nil -> %>
        <div class="text-primary text-8xl font-extrabold">
          You are not in duel this round. Sit back and relax mate :)
        </div>
      <% true -> %>
        <form class="flex flex-col w-full gap-4" phx-submit="answer">
          <div class="text-xl">
            {@prompt}
          </div>
          <div class="w-full space-y-4">
            <input
              name="answer"
              type="text"
              class="input w-full input-bordered"
              placeholder="Put your answer here :)"
            />
            <button class="btn btn-primary w-full">Submit</button>
          </div>
        </form>
    <% end %>
    """
  end
end
