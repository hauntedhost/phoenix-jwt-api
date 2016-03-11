defmodule Jot.GuardianAuthToken do
  use Guardian.Hooks
  import Ecto.Changeset, only: [change: 2]
  import Ecto.Query, only: [from: 1, from: 2]
  alias Jot.Repo
  alias Jot.User
  alias Jot.AuthToken
  alias Jot.UserQuery

  @doc """
  Callback after the JWT is generated. Creates new AuthToken for user.
  """
  def after_encode_and_sign(user = %User{}, type, claims, jwt) do
    IO.puts("AFTER_ENCODE_AND_SIGN")
    case create_user_auth_token(user, jwt, claims) do
      {:error, _} -> {:error, :token_storage_failure}
      _           -> {:ok, {user, type, claims, jwt}}
    end
  end

  @doc """
  Callback when a token is verified, check to make sure that it is present in the DB.
  If the token is found, the verification continues. If not an error is returned.
  """
  def on_verify(claims = %{"aud" => "User:" <> user_id}, jwt) do
    case find_active_user_token(user_id, claims) do
      nil    -> {:error, :token_not_found}
      _token -> {:ok, {claims, jwt}}
    end
  end

  @doc """
  Callback when logging out.
  If a token is found, #revoke is called.
  If a token is not found, no error is raised, the claims and jwt are simply passed through.
  """
  def on_revoke(claims = %{"aud" => "User:" <> user_id}, jwt) do
    IO.puts("ON_REVOKE")
    case revoke_user_auth_token(user_id, claims) do
      :not_found           -> {:ok, {claims, jwt}}
      {:ok, token}         -> {:ok, {claims, jwt}}
      {:error, _changeset} -> {:error, :could_not_revoke_token}
    end
  end

  # PRIVATE

  def find_active_user_token(user_id, %{"jti" => jti, "aud" => aud}) do
    Repo.one from t in AuthToken,
      where:
        t.user_id == ^user_id and
        t.jti == ^jti and
        t.aud == ^aud and
        is_nil(t.revoked_at)
  end

  defp create_user_auth_token(user, token, claims) do
    claims = Guardian.Claims.nbf(claims) # enriches claims with nbf
    changeset = AuthToken.login_changeset(user, token, claims)
    Repo.insert(changeset)
  end

  def revoke_user_auth_token(user_id, claims) do
    case find_active_user_token(user_id, claims) do
      nil   -> :not_found
      token ->
        token
        |> change(%{revoked_at: Ecto.DateTime.utc})
        |> Repo.update
    end
  end
end
