defmodule Jot.Endpoint do
  use Phoenix.Endpoint, otp_app: :jot

  # A plug for serving static assets from "priv/static" directory
  plug Plug.Static,
    at: "/",
    from: :jot,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # A plug for generating a unique request id for each request
  plug Plug.RequestId

  # A plug for logging basic request information
  plug Plug.Logger

  # A plug for parsing the request body
  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json], # modules to be invoked for parsing
    pass: ["*/*"], # MIME type strings that are allowed
    json_decoder: Poison

  # A Plug to convert HEAD requests to GET requests.
  plug Plug.Head

  # A plug to add CORS
  plug CORSPlug,
    Application.get_env(:jot, CORSPlug, [])

  # A DSL to define a routing algorithm that works with Plug
  plug Jot.Router
end
