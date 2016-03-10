# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.
use Mix.Config

# Configures the endpoint
config :jot, Jot.Endpoint,
  url: [host: "localhost"],
  root: Path.dirname(__DIR__),
  secret_key_base: "lAfeYVqGqMjYULcrlW3G5i94LEwzyc2yUXV7+VfyBO3jMW/H0M/XZ9JxeKbkfZts",
  render_errors: [accepts: ~w(html json)],
  pubsub: [name: Jot.PubSub,
           adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env}.exs"

# Configure phoenix generators
config :phoenix, :generators,
  migration: true,
  binary_id: false

config :joken, config_module: Guardian.JWT

# FIXME: per-environment secret_key!
config :guardian, Guardian,
  hooks: GuardianDb,
  issuer: "Jot",
  ttl: {30, :days},
  verify_issuer: true,
  secret_key: "lksdjowiurowieurlkjsdlwwer",
  serializer: Jot.TokenSerializer

config :guardian_db, GuardianDb,
  repo: Jot.Repo,
  delete_revoked: false
