defmodule QwhiplashWeb.Router do
  use QwhiplashWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {QwhiplashWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug QwhiplashWeb.Plugs.SessionId
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", QwhiplashWeb do
    pipe_through :browser

    # get "/", PageController, :home

    live_session :default do
      live "/", HomeLive
      live "/host", HostLive
      live "/game/:game_code", GameLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", QwhiplashWeb do
  #   pipe_through :api
  # end
end
