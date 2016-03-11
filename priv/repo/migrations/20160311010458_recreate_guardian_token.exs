defmodule Jot.Repo.Migrations.RecreateGuardianToken do
  use Ecto.Migration

  def change do
    drop_if_exists table(:guardian_tokens)
    create table(:auth_tokens, primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references(:users, type: :binary_id, on_delete: :nilify_all)

      add :jwt, :text
      add :typ, :string

      add :claims, :map
      add :iss, :string
      add :sub, :string
      add :aud, :string
      add :exp, :bigint
      add :nbf, :bigint
      add :iat, :bigint
      add :jti, :string

      add :expires_at, :datetime
      add :revoked_at, :datetime

      timestamps
    end
    create unique_index(:auth_tokens, [:jti, :aud])
    create unique_index(:auth_tokens, [:user_id, :jti, :aud])
  end
end
