defmodule QwhiplashWeb.Plugs.SessionId do
  import Plug.Conn
  require Logger

  def init(default), do: default

  def call(conn, _config) do
    case get_session(conn, :session_id) do
      nil ->
        session_id = unique_session_id()
        Logger.debug("Generated session_id: #{session_id}")
        put_session(conn, :session_id, session_id) |> assign(:session_id, session_id)

      session_id ->
        Logger.debug("Generated session_id: #{session_id}")
        conn |> assign(:session_id, session_id)
    end
  end

  defp unique_session_id() do
    :crypto.strong_rand_bytes(16) |> Base.encode16()
  end
end
