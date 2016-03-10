defmodule Jot.AuthTokenController do
  use Jot.Web, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Jot.Repo
  alias Jot.User

  def create(conn, params = %{"email" => _, "password" => _}) do
    case login(conn, params) do
      {:ok, user} ->
        response = %{
          jwt: new_api_token(user),
          user: %{
            id: user.id,
            email: user.email
          }
        }
        conn
        |> put_status(:created)
        |> json(response)
      {:error, status} ->
        response = %{error: status}
        conn
        |> put_status(status)
        |> json(response)
    end
  end

  defp login(conn, %{"email" => email, "password" => given_pass}) do
    user = Repo.get_by(User, email: email)
    cond do
      user && checkpw(given_pass, user.password_hash) ->
        {:ok, user}
      user ->
        {:error, :unauthorized}
      true ->
        dummy_checkpw()
        {:error, :not_found}
    end
  end

  defp new_api_token(user) do
    {:ok, token, claims} = Guardian.encode_and_sign(user, :api)
    token
  end
end
