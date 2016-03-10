defmodule Jot.PageController do
  use Jot.Web, :controller

  def public_page(conn, params) do
    response = %{
      public: true,
      hello: "world"
    }
    json(conn, response)
  end

  def secret_page(conn, params) do
    current_user = conn.assigns[:current_user]
    response = %{
      top_secret: true,
      current_user: %{
        id: current_user.id,
        email: current_user.email
      }
    }
    json(conn, response)
  end
end
