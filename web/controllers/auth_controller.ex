defmodule Jot.AuthController do
  use Jot.Web, :controller
  import Comeonin.Bcrypt, only: [checkpw: 2, dummy_checkpw: 0]
  alias Jot.Repo
  alias Jot.User

  def create(conn, params = %{"email" => _, "password" => _}) do
    case login_by_email_and_pass(conn, params) do
      {:ok, user} ->
        response = %{
          success: true,
          token: "no-worries",
          user: %{id: user.id, email: user.email}
        }
        conn
        |> put_status(:created)
        |> Guardian.Plug.sign_in(user)
        |> json(response)

      {:error, :token_storage_failure} ->
        conn
        |> put_status(:error)
        |> json(%{error: "token_storage_failure"})

      {:error, status} ->
        conn
        |> put_status(status)
        |> json(%{error: status})
    end
  end

  def delete(conn, _params) do
    conn
    |> Guardian.Plug.sign_out
    |> put_status(:ok)
    |> json(%{success: true})
  end

  # GitHub
  def oauth(conn, %{"provider" => "github", "code" => code}) do
    # GET ACCESS TOKEN
    auth_url = "https://github.com/login/oauth/access_token"
    [client_id: client_id, client_secret: client_secret] = Application.get_env(:jot, Jot.OAuth.GitHub)
    {:ok, %HTTPoison.Response{body: auth_body}} = HTTPoison.post(auth_url, {:form,
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

  # Facebook
  def oauth(conn, %{"provider" => "facebook", "code" => code, "redirect_uri" => redirect_uri}) do
    # GET ACCESS TOKEN
    auth_url = "https://graph.facebook.com/oauth/access_token"
    [client_id: client_id, client_secret: client_secret] = Application.get_env(:jot, Jot.OAuth.Facebook)
    {:ok, response = %HTTPoison.Response{body: auth_body}} =  HTTPoison.get(auth_url, [], params: %{
      code: code,
      client_id: client_id,
      client_secret: client_secret,
      redirect_uri: redirect_uri # required :/
    })
    %{"access_token" => access_token} = URI.decode_query(auth_body)

    # TODO: can i possibly skip this second GET by querying for a user by their github access_token?
    IO.inspect(access_token)

    # GET USER INFO
    {:ok, %HTTPoison.Response{body: user_body}} = HTTPoison.get("https://graph.facebook.com/me", [
      Authorization: "OAuth #{access_token}"
    ])
    {:ok, %{"email" => email}} = Poison.decode(user_body)

    # TODO: FIND OR CREATE USER BY EMAIL
    # find or create user by email (need to handle possibility of users with nil passwords)

    # FIXME: do not return actual access_token
    # return JWT or server-generated session key associated with user
    json(conn, %{auth_token: access_token, email: email})
  end

  # private

  # NOTE: currently not used, this function can be used to generate a valid token
  # for a client that cannot send tokens via session cookies
  defp generate_user_token(user) do
    {:ok, token, _claims} = Guardian.encode_and_sign(user)
    token
  end

  defp login_by_email_and_pass(conn, %{"email" => email, "password" => given_pass}) do
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
end
