defmodule Jot.AuthController do
  use Jot.Web, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Jot.Repo
  alias Jot.User

  def create(conn, params = %{"email" => _, "password" => _}) do
    {status, response} = case login(conn, params) do
      {:ok, user} ->
        {:created, %{
          success: true,
          token: generate_user_token(user),
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

  def github_oauth(conn, %{"code" => code}) do
    # GET ACCESS TOKEN
    github_auth_url = "https://github.com/login/oauth/access_token"
    [client_id: client_id, client_secret: client_secret] = Application.get_env(:jot, Jot.GithubOAuth)
    {:ok, %HTTPoison.Response{body: auth_body}} = HTTPoison.post(github_auth_url, {:form,
      code: code,
      client_id: client_id,
      client_secret: client_secret
    })
    %{"access_token" => access_token} = URI.decode_query(auth_body)

    # TODO: can i possibly skip this second GET by querying for a user by their github access_token?
    IO.inspect(access_token)

    # GET USER INFO
    {:ok, %HTTPoison.Response{body: user_body}} = HTTPoison.get("https://api.github.com/user", [
      Authorization: "token #{access_token}"
    ])
    {:ok, %{"email" => email}} = Poison.decode(user_body)

    # TODO: FIND OR CREATE USER BY EMAIL
    # find or create user by email (need to handle possibility of users with nil passwords)

    # FIXME: do not return actual access_token
    # return JWT or server-generated session key associated with user
    json(conn, %{auth_token: access_token, email: email})
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

  defp generate_user_token(user) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user, :auth_token)
    token
  end

  defp current_token_and_claims(conn) do
    token = Guardian.Plug.current_token(conn)
    {:ok, claims} = Guardian.Plug.claims(conn)
    {token, claims}
  end

  defp current_user(conn) do
    Guardian.Plug.current_resource(conn)
  end
end
