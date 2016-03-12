defmodule Jot.GuardianAuthToken do
  use Guardian.Hooks
  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 1, from: 2]
  alias Jot.Repo
  alias Jot.User
  alias Jot.AuthToken

  @doc """
  Callback after the JWT is generated. Creates new AuthToken for user or returns error.
  """
  def after_encode_and_sign(user = %User{}, type, claims, jwt) do
    case create_user_auth_token(user.id, jwt, claims) do
      {:error, _} -> {:error, :token_storage_failure}
      _           -> {:ok, {user, type, claims, jwt}}
    end
  end

  @doc """
  Callback when a token is verified, check to make sure that it is present in the DB.
  If the token is found, the verification continues. If not an error is returned.
  """
  def on_verify(claims = %{"aud" => "User:" <> user_id, "typ" => type}, jwt) do
    case find_active_user_and_token(user_id, claims) do
      %{user: nil, token: nil}  -> {:error, :match_not_found}
      %{user: nil, token: _t}   -> {:error, :user_not_found}
      %{user: user, token: nil} -> {:error, :token_not_found}
        # OPTION: user exists but token does not. store this token for them.
        # this is probably a terrible idea.
        # case create_user_auth_token(user.id, jwt, claims) do
        #   {:error, _} -> {:error, :token_storage_failure}
        #   _           -> {:ok, {claims, jwt}}
        # end
      %{user: _u, token: _t}    -> {:ok, {claims, jwt}}
    end
  end

  @doc """
  Callback when logging out. If a token is found, it is revoked, or an error is returned.
  If a token is not found, no error is returned, the claims and jwt are passed through.
  """
  def on_revoke(claims = %{"aud" => "User:" <> user_id}, jwt) do
    case revoke_user_auth_token(user_id, claims) do
      :not_found           -> {:ok, {claims, jwt}}
      {:ok, _token}        -> {:ok, {claims, jwt}}
      {:error, _changeset} -> {:error, :could_not_revoke_token}
    end
  end

  # PRIVATE

  def find_active_user_and_token(user_id, %{"jti" => jti, "aud" => aud}) do
    Repo.one from u in User,
      where: u.id == ^user_id,
      left_join: t in AuthToken,
      on:
        t.user_id == ^user_id and
        t.jti == ^jti and
        t.aud == ^aud and
        is_nil(t.revoked_at),
      select: %{
        user: u,
        token: t
      }
  end

  defp create_user_auth_token(user_id, token, claims) do
    claims = Guardian.Claims.nbf(claims) # enriches claims with nbf
    changeset = AuthToken.login_changeset(user_id, token, claims)
    Repo.insert(changeset)
  end

  def revoke_user_auth_token(user_id, claims) do
    case find_active_user_and_token(user_id, claims) do
      %{token: nil}   -> :not_found
      %{token: token} ->
        token
        |> change(%{revoked_at: Ecto.DateTime.utc})
        |> Repo.update
    end
  end
end
