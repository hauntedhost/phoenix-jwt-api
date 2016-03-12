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

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.Session,
    store: :cookie,
    key: "_jot_key",
    signing_salt: "7cWY2XDx"

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
