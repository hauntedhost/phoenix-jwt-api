ExUnit.start

Mix.Task.run "ecto.create", ~w(-r Jot.Repo --quiet)
Mix.Task.run "ecto.migrate", ~w(-r Jot.Repo --quiet)
Ecto.Adapters.SQL.begin_test_transaction(Jot.Repo)

