defmodule Jot.AuthSuccess do
  import Plug.Conn, only: [assign: 3]

  def init(_) do
    nil
  end

  def call(conn, _opts) do
    current_user = Guardian.Plug.current_resource(conn)
    assign(conn, :current_user, current_user)
  end
end
