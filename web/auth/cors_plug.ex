defmodule Jot.CorsPlug do
  import Plug.Conn

  def defaults do
    [
      origin:      "*",
      credentials: true,
      max_age:     1728000,
      headers:     ["Authorization", "Content-Type", "Accept", "Origin",
                    "User-Agent", "DNT","Cache-Control", "X-Mx-ReqToken",
                    "Keep-Alive", "X-Requested-With", "If-Modified-Since",
                    "X-CSRF-Token"],
      expose:      [],
      methods:     ["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"]
    ]
  end

  def init(options) do
    Keyword.merge(defaults, options)
  end

  defp origin do
    Application.get_env(:jot, Jot.CorsPlug, [])[:origin] || "*"
  end

  def call(conn, options) do
    new_resp_headers = conn.resp_headers ++ headers(conn, options)
    conn = put_in(conn.resp_headers, new_resp_headers)
    case conn.method do
      "OPTIONS" -> conn |> send_resp(204, "") |> halt()
      _method   -> conn
    end
  end

  # headers specific to OPTIONS request
  defp headers(conn = %Plug.Conn{method: "OPTIONS"}, options) do
    headers(%{conn | method: nil}, options) ++ [
      {"access-control-max-age", "#{options[:max_age]}"},
      {"access-control-allow-headers", Enum.join(options[:headers], ",")},
      {"access-control-allow-methods", Enum.join(options[:methods], ",")}
    ]
  end

  # universal headers
  defp headers(conn, options) do
    [
      {"access-control-allow-origin", origin(options[:origin], conn)},
      {"access-control-expose-headers", Enum.join(options[:expose], ",")},
      {"access-control-allow-credentials", "#{options[:credentials]}"}
    ]
  end

  # normalize non-list to list
  defp origin(key, conn) when not is_list(key) do
    origin(List.wrap(key), conn)
  end

  # whitelist internal requests
  defp origin([:self], conn) do
    get_req_header(conn, "origin") |> List.first || "*"
  end

  # return "*" if origin list is ["*"]
  defp origin(["*"], _conn) do
    "*"
  end

  # return requesting origin if in origin list, otherwise "null" string
  defp origin(origins, conn) when is_list(origins) do
    req_origin = get_req_header(conn, "origin") |> List.first
    if req_origin in origins, do: req_origin, else: "null"
  end
end
