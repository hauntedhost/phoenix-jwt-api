defmodule Jot.AuthTokenController do
  use Jot.Web, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Jot.Repo
  alias Jot.User

  def create(conn, params = %{"email" => _, "password" => _}) do
    {status, response} = case login(conn, params) do
      {:ok, user} ->
        {:created, %{
          success: true,
          token: new_api_token(user),
          user: %{id: user.id, email: user.email}
        }}
      {:error, :token_storage_failure} ->
        {:internal_server_error, %{error: "token_storage_failure"}}
      {:error, status} ->
        {status, %{error: status}}
    end

    conn
    |> put_status(status)
    |> json(response)
  end

  def delete(conn, _params) do
    {status, response} = case logout(conn) do
      :ok ->
        {:ok, %{success: true}}
      {:error, reason} ->
        {:internal_server_error, %{error: reason}}
    end

    conn
    |> put_status(status)
    |> json(response)
  end

  # private

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

  defp logout(conn) do
    {token, claims} = current_token_and_claims(conn)
    Guardian.revoke!(token, claims)
  end

  defp new_api_token(user) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user, :api)
    token
  end

  defp current_user(conn) do
    Guardian.Plug.current_resource(conn)
  end

  defp current_token_and_claims(conn) do
    token = Guardian.Plug.current_token(conn)
    {:ok, claims} = Guardian.Plug.claims(conn)
    {token, claims}
  end
end
