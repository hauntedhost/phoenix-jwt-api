defmodule Jot.TokenSerializer do
   @behaviour Guardian.Serializer
   alias Jot.Repo
   alias Jot.User

   def for_token(user = %User{}) do
     {:ok, "User:#{user.id}"}
   end

   def for_token(_) do
     {:error, "Unknown resource type"}
   end

   def from_token("User:" <> id) do
     user = Repo.get_by_uuid!(User, id)
     {:ok, user}
   end

   def from_token(_) do
     {:error, "Unknown resource type"}
   end
end
