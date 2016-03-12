defmodule Jot.AuthToken do
  use Jot.Web, :model
  alias Jot.AuthToken
  alias Jot.User

  @primary_key {:id, :binary_id, autogenerate: true}

  schema "auth_tokens" do
    field :jwt, :string
    field :typ, :string

    field :claims, :map
    field :iss, :string
    field :sub, :string
    field :aud, :string
    field :exp, :integer
    field :nbf, :integer
    field :iat, :integer
    field :jti, :string

    field :expires_at, Ecto.DateTime
    field :revoked_at, Ecto.DateTime

    belongs_to :user, Jot.User, type: :binary_id

    timestamps
  end

  def login_changeset(user_id, token, claims = %{}) do
    expires_at = Jot.Timestamp.to_ecto_datetime(claims["exp"])
    fields = claims
    |> Map.put("user_id", user_id)
    |> Map.put("jwt", token)
    |> Map.put("claims", claims)
    |> Map.put("expires_at", expires_at)

    required_fields = ~w(jwt user_id jwt aud exp jti claims expires_at)
    optional_fields = ~w(typ iss sub nbf iat)

    %AuthToken{}
    |> cast(fields, required_fields, optional_fields)
  end
end
