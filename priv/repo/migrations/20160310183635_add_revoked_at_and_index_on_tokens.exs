defmodule Jot.Repo.Migrations.AddRevokedAtAndIndexOnTokens do
  use Ecto.Migration

  def change do
    alter table(:guardian_tokens) do
      add :revoked_at, :datetime
    end
    create unique_index(:guardian_tokens, [:jti, :aud])
  end
end
