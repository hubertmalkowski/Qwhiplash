defmodule QwhiplashWeb.GameComponents do
  use Phoenix.Component
  alias Phoenix.LiveView.JS

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

  attr :voting, :boolean, default: false, doc: "Whether the player can vote or not"
  attr :duel, :any, required: false
  attr :voted, :boolean, default: false

  def voting(assigns) do
    ~H"""
    {@voted}
    <%= cond do %>
      <% @voted == true -> %>
        <div class="text-primary text-8xl font-extrabold">
          Waiting for other players to vote
        </div>
      <% @voting == false -> %>
        <div class="text-primary text-8xl font-extrabold">
          You are not voting this round
        </div>
      <% true -> %>
        <div class="flex flex-col gap-4 pt-4" id="answers">
          <%= for {player_id, answer} <- @duel.answers do %>
            <button
              phx-value-answerer={player_id}
              phx-click={JS.push("vote") |> JS.hide(to: "#answers")}
              class="btn card card-body shadow-md bg-base-200 text-2xl font-bold"
            >
              <%= if answer.answer == "" or answer.answer == nil do %>
                <span class="text-base-content/60 italic">
                  Frajer nie odpowiedział xd
                </span>
              <% else %>
                {answer.answer}
              <% end %>
            </button>
          <% end %>
        </div>
    <% end %>
    """
  end
end
