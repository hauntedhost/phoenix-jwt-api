defmodule Jot.Router do
  use Jot.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.LoadResource
  end

  pipeline :require_authentication do
    plug Guardian.Plug.EnsureAuthenticated, handler: Jot.AuthError
    plug Jot.AuthSuccess
  end

  scope "/api/secret", Jot do
    pipe_through [:api, :require_authentication]

    get "/", PageController, :secret_page
  end

  scope "/api", Jot do
    pipe_through [:api]

    get "/", PageController, :public_page
    post "/login", AuthController, :create
    post "/github_oauth", AuthController, :github_oauth

    scope "/logout" do
      pipe_through [:require_authentication]
      delete "/", AuthController, :delete
    end
  end
end
